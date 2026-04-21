extends VehicleBody3D
class_name Vehicle3D


@export var vehicle_name: String = 'Vehicle'
@export var max_steering_angle: float = 0.5 # radians
@export var max_engine_force: float = 200 # max_engine_force
@export var max_brake: float = 10 # max_engine_force

var _target_engine_force: float = 0.0
var _target_brake: float = 0.0
var _target_steering: float = 0.0


func _ready():
	self.add_to_group("vehicles")


func _physics_process(delta):
	engine_force = _target_engine_force
	brake = _target_brake
	steering = lerp(steering, _target_steering, 10.0 * delta)


func accelerate(amount: float):
	_target_engine_force = amount


func steer(angle: float):
	_target_steering = angle


func apply_brake(amount: float):
	_target_brake = amount


# >
# >
# >


# must reset values after user has stopped pushing acclerate pedal
func reset_vehicle_controls(delta):
	_target_engine_force = 0.0
	_target_brake = 0.0
	_target_steering = 0.0
