extends Node3D
class_name Player

var lap: int = 0
var timer: float = 0.0
var finished: bool = false
var distance_traveled: float = 0.0

var upcoming_waypoints: Array = []
var _waypoint_start_index: int = 0
var _print_timer: float = 0.0
var _w1_marker: MeshInstance3D

func _ready() -> void:
	$AIController3D.init(self)

	# G-meter overlay bottom-left
	var gmeter_scene := preload("res://Player/GMeter.tscn")
	var canvas := CanvasLayer.new()
	canvas.layer = 3
	add_child(canvas)
	var gmeter := gmeter_scene.instantiate()
	gmeter.car = $BasicCar
	gmeter.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	gmeter.custom_minimum_size = Vector2(160, 160)
	gmeter.offset_top = -160.0
	gmeter.offset_bottom = 0.0
	canvas.add_child(gmeter)

	# Minimap arrow: horizontal cone on render layer 2, invisible to main camera
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 20.0
	cone.height = cone.bottom_radius * 2.5
	var arrow_mat := StandardMaterial3D.new()
	arrow_mat.albedo_color = Color.RED
	arrow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var minimap_arrow := MeshInstance3D.new()
	minimap_arrow.mesh = cone
	minimap_arrow.material_override = arrow_mat
	minimap_arrow.layers = 2
	var half_height := cone.bottom_radius * 2.5 / 2.0
	minimap_arrow.position = Vector3(half_height, 12, 0)  # shift so car sits at arrow base
	minimap_arrow.rotation_degrees = Vector3(90, 90, 0)
	$BasicCar.add_child(minimap_arrow)

	# Put a red marker above next target waypoint
	var sphere := SphereMesh.new()
	sphere.radius = 2.0
	sphere.height = 4.0

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_w1_marker = MeshInstance3D.new()
	_w1_marker.mesh = sphere
	_w1_marker.material_override = mat
	get_tree().current_scene.add_child.call_deferred(_w1_marker)

func set_waypoints(waypoints: Array, start_index: int) -> void:
	upcoming_waypoints = waypoints
	_waypoint_start_index = start_index

func _print_waypoint_info() -> void:
	var car := $BasicCar
	var car_pos : Vector3 = car.global_position
	var car_basis : Basis = car.global_transform.basis
	var parts: Array = []
	for i in range(upcoming_waypoints.size()):
		var wp: Vector3 = upcoming_waypoints[i]
		var world_offset := Vector3(wp.x - car_pos.x, 0.0, wp.z - car_pos.z)
		var local_offset := car_basis.inverse() * world_offset
		# local_offset.x = forward(+)/back(-), local_offset.z = left(+)/right(-)
		var dist := world_offset.length()
		parts.append("W%02d(fwd %.0f, side %.0f) d=%.0f" % [_waypoint_start_index + i, local_offset.x, -local_offset.z, dist])
	var speed : float = $BasicCar.linear_velocity.length()
	parts.append("spd %.1f" % speed)
	parts.append("rwd %.4f" % $AIController3D.reward)
	print(" | ".join(parts))


func _physics_process(delta):
	var ai := $AIController3D
	if ai.needs_reset:
		ai.reset()
		return

	if upcoming_waypoints.size() > 0 and _w1_marker.is_inside_tree():
		var w1: Vector3 = upcoming_waypoints[0]
		_w1_marker.global_position = Vector3(w1.x, w1.y + 5.0, w1.z)

	_print_timer += delta
	if _print_timer >= 1.0:
		_print_timer = 0.0
		#_print_waypoint_info()
		#var sensor := $BasicCar.get_node_or_null("CarPathRaySensor3D")
		#if sensor:
			#print("ray_obs: ", sensor.get_observations())

	if ai.heuristic == "human":
		if Input.is_action_pressed("ui_forward"):
			$BasicCar.accelerate($BasicCar.max_engine_force)
		elif Input.is_action_pressed("ui_backward"):
			$BasicCar.apply_brake($BasicCar.max_brake)
		else:
			$BasicCar.reset_vehicle_controls(delta)
		var turn := Input.get_axis("ui_left", "ui_right")
		$BasicCar.steer(-turn * $BasicCar.max_steering_angle)
	else:
		if ai.throttle_action > 0.0:
			$BasicCar.accelerate(ai.throttle_action * $BasicCar.max_engine_force)
		elif ai.throttle_action < 0.0:
			$BasicCar.apply_brake(-ai.throttle_action * $BasicCar.max_brake)
		else:
			$BasicCar.reset_vehicle_controls(delta)
		$BasicCar.steer(ai.steer_action * $BasicCar.max_steering_angle)
