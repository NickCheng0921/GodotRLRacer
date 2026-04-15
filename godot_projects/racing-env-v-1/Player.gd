extends Node3D
class_name Player

var lap: int = 0
var timer: float = 0.0
var finished: bool = false
var distance_traveled: float = 0.0

var upcoming_waypoints: Array = []
var _print_timer: float = 0.0
var _w1_marker: MeshInstance3D

func _ready() -> void:
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

func set_waypoints(waypoints: Array) -> void:
	upcoming_waypoints = waypoints

func _print_waypoint_info() -> void:
	var car_pos : Vector3 = $BasicCar.global_position
	var parts: Array = []
	for i in range(upcoming_waypoints.size()):
		var wp: Vector3 = upcoming_waypoints[i]
		var dx := wp.x - car_pos.x
		var dz := wp.z - car_pos.z
		var dist := sqrt(dx * dx + dz * dz)
		parts.append("W%d(rel %.0f,%.0f) d=%.0f" % [i + 1, dx, dz, dist])
	print(" | ".join(parts))

func _physics_process(delta):
	if upcoming_waypoints.size() > 0 and _w1_marker.is_inside_tree():
		var w1: Vector3 = upcoming_waypoints[0]
		_w1_marker.global_position = Vector3(w1.x, w1.y + 5.0, w1.z)

	_print_timer += delta
	if _print_timer >= 1.0:
		_print_timer = 0.0
		_print_waypoint_info()

	if Input.is_action_pressed("ui_forward"):
		$BasicCar.accelerate($BasicCar.max_engine_force)
	elif Input.is_action_pressed("ui_backward"):
		$BasicCar.apply_brake($BasicCar.max_brake)
	else:
		$BasicCar.reset_vehicle_controls(delta)

	var turn = Input.get_axis("ui_left", "ui_right")
	$BasicCar.steer(-turn * $BasicCar.max_steering_angle)
