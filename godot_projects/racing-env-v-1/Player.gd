extends Node3D
class_name Player

var lap: int = 0
var timer: float = 0.0
var finished: bool = false
var distance_traveled: float = 0.0

func _physics_process(delta):
	if Input.is_action_pressed("ui_forward"):
		$BasicCar.accelerate($BasicCar.max_engine_force)
	elif Input.is_action_pressed("ui_backward"):
		$BasicCar.apply_brake($BasicCar.max_brake)
	else:
		$BasicCar.reset_vehicle_controls(delta)

	var turn = Input.get_axis("ui_left", "ui_right")
	$BasicCar.steer(-turn * $BasicCar.max_steering_angle)
