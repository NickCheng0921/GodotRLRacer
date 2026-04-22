extends Node3D

const WAYPOINT_LOOKAHEAD := 2
const WAYPOINT_ADVANCE_DIST := 8.0 # increment waypoint counter when we get close enough

var _waypoints: Array = []
var _waypoint_index: int = 1
var _car: RigidBody3D
var _tp_cooldown: float = 0.0
var _ai: Node3D
var _prev_dist_to_target: float = 0.0
var _prev_velocity: Vector3 = Vector3.ZERO
var _lateral_g_smooth: float = 0.0
var _print_timer: float = 0.0

const LATERAL_G_PENALTY := 0.002
const LATERAL_G_SMOOTH  := 0.15 # running average lateral g force for lerp
const GRAVITY := 9.8

func _ready() -> void:
	_setup_topdown_viewport()
	_setup_waypoints()
	_car = $Player/BasicCar
	var main_cam: Camera3D = $Player/BasicCar/Camera3D
	main_cam.cull_mask &= ~(1 << 1)  # hide render layer 2 (minimap arrow)
	_ai = $Player/AIController3D
	_ai.action_repeat = 8 # update action every n frames (hold for n)
	_push_waypoints_to_player()
	var tp : Vector3 = _waypoints[_waypoint_index].global_position
	_prev_dist_to_target = Vector2(_car.global_position.x - tp.x, _car.global_position.z - tp.z).length()

func _push_waypoints_to_player() -> void:
	var player: Player = $Player
	player.set_waypoints(get_next_waypoints(WAYPOINT_LOOKAHEAD), _waypoint_index)

func get_next_waypoints(n: int) -> Array:
	var result: Array = []
	for i in range(n):
		var idx := (_waypoint_index + i) % _waypoints.size()
		result.append(_waypoints[idx].global_position)
	return result

func _physics_process(delta: float) -> void:
	if _tp_cooldown > 0.0:
		_tp_cooldown -= delta
		return
	_check_waypoint_advance()
	_check_off_road()
	_reward_progress()
	_reward_throttle()
	_penalize_lateral_g(delta)
	#_print_timer += delta
	#if _print_timer >= 0.5:
		#_print_timer = 0.0
		#print("reward: %.4f" % _ai.reward)

func _penalize_lateral_g(delta: float) -> void:
	var accel := (_car.linear_velocity - _prev_velocity) / delta
	_prev_velocity = _car.linear_velocity
	var right     := -_car.global_transform.basis.z
	var raw_g     := absf(accel.dot(right) / GRAVITY)
	_lateral_g_smooth = lerpf(_lateral_g_smooth, raw_g, LATERAL_G_SMOOTH)
	_ai.reward -= _lateral_g_smooth * LATERAL_G_PENALTY

func _reward_throttle() -> void:
	if _ai.throttle_action > 0.0:
		_ai.reward += _ai.throttle_action * 0.01

func _reward_progress() -> void:
	var tp : Vector3 = _waypoints[_waypoint_index].global_position
	var cp := _car.global_position
	var curr_dist := Vector2(cp.x - tp.x, cp.z - tp.z).length()
	if _car.linear_velocity.length() > 0.5:
		_ai.reward += (_prev_dist_to_target - curr_dist) * 0.01
	_prev_dist_to_target = curr_dist

func _check_waypoint_advance() -> void:
	var target := _waypoints[_waypoint_index] as Node3D
	var cp := _car.global_position
	var tp := target.global_position
	var xz_dist := Vector2(cp.x - tp.x, cp.z - tp.z).length()
	if xz_dist < WAYPOINT_ADVANCE_DIST:
		_waypoint_index = (_waypoint_index + 1) % _waypoints.size()
		_push_waypoints_to_player()
		_ai.reward += 1.0

func _setup_waypoints() -> void:
	var wp_root = $Track/Waypoints
	_waypoints = wp_root.get_children()
	_waypoints.sort_custom(func(a, b):
		var a_n := str(a.name).split("_")[-1].to_int()
		var b_n := str(b.name).split("_")[-1].to_int()
		return a_n < b_n)

func _is_over_road() -> bool:
	var space_state := get_world_3d().direct_space_state
	var from := _car.global_position + Vector3.UP * 1.0
	var to   := _car.global_position + Vector3.DOWN * 5.0
	# Layer 2 only — road Area3D, ignores ground and everything else
	var query := PhysicsRayQueryParameters3D.create(from, to, 2)
	query.collide_with_areas = true
	var result := space_state.intersect_ray(query)
	return not result.is_empty()

func _check_off_road() -> void:
	if not is_instance_valid(_car):
		return
	if not _is_over_road() or _is_flipped():
		var idx := (_waypoint_index - 1 + _waypoints.size()) % _waypoints.size()
		_teleport_to_waypoint(idx)

func _is_flipped() -> bool:
	return _car.global_transform.basis.y.dot(Vector3.UP) < 0.0


func _teleport_to_waypoint(idx: int) -> void:
	var wp      := _waypoints[idx] as Node3D
	var next_wp := _waypoints[(idx + 1) % _waypoints.size()] as Node3D

	var forward: Vector3 = (next_wp.global_position - wp.global_position).normalized()
	var new_basis := Basis.looking_at(forward, Vector3.UP).rotated(Vector3.UP, PI / 2.0)

	_car.global_transform = Transform3D(new_basis, wp.global_position + Vector3.UP * 0.5)
	_car.linear_velocity  = Vector3.ZERO
	_car.angular_velocity = Vector3.ZERO
	_prev_velocity = Vector3.ZERO
	_lateral_g_smooth = 0.0
	_tp_cooldown = 2.0
	var tp : Vector3 = _waypoints[_waypoint_index].global_position
	_prev_dist_to_target = Vector2(_car.global_position.x - tp.x, _car.global_position.z - tp.z).length()
	_ai.reward -= 1.0

# Create a small UI in bottom right w/ top down view
func _setup_topdown_viewport() -> void:
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 2
	add_child(canvas_layer)

	var container = SubViewportContainer.new()
	container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	container.custom_minimum_size = Vector2(300, 200)
	container.offset_left = -300
	container.offset_top = -200
	container.offset_right = 0
	container.offset_bottom = 0
	canvas_layer.add_child(container)

	var viewport = SubViewport.new()
	viewport.size = Vector2i(300, 200)
	container.add_child(viewport)

	var cam = Camera3D.new()
	cam.position = Vector3(0, 477.833, 0)
	cam.rotation_degrees = Vector3(-90, 0, 0)
	viewport.add_child(cam)
