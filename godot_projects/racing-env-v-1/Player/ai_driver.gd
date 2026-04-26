extends AIController3D

const MAX_SPEED := 50.0  # m/s, used to normalise speed observation
const STEER_CHANGE_PENALTY := 0.03
const STEER_SMOOTH_WINDOW := 0.5  # seconds to average steer history over

var throttle_action: float = 0.0
var steer_action: float = 0.0

var _steer_history: Array = []  # Array of [timestamp, steer_value]
var _time_elapsed: float = 0.0

func _physics_process(delta: float) -> void:
	_time_elapsed += delta
	var cutoff := _time_elapsed - STEER_SMOOTH_WINDOW
	_steer_history = _steer_history.filter(func(e): return e[0] >= cutoff)

func get_obs() -> Dictionary:
	var car: RigidBody3D = _player.get_node("BasicCar")
	var car_pos := car.global_position
	var car_basis := car.global_transform.basis

	var obs: Array = []
	obs.append(car.linear_velocity.length() / MAX_SPEED)

	var grounded := 0.0
	for child in car.get_children():
		if child is VehicleWheel3D and child.is_in_contact():
			grounded = 1.0
			break
	obs.append(grounded)

	for wp: Vector3 in _player.upcoming_waypoints:
		var world_offset := Vector3(wp.x - car_pos.x, 0.0, wp.z - car_pos.z)
		var local_offset := car_basis.inverse() * world_offset
		obs.append(local_offset.x)   # forward (+) / back (-)
		obs.append(-local_offset.z)  # right (+) / left (-)

	var sensor := car.get_node_or_null("CarPathRaySensor3D")
	if sensor:
		var ray_obs : Array[float] = sensor.get_observations()
		obs.append_array(ray_obs)

	return {"obs": obs}

func get_reward() -> float:
	return reward

func get_action_space() -> Dictionary:
	return {
		"throttle_action": {"size": 1, "action_type": "continuous"},
		"steer_action":    {"size": 1, "action_type": "continuous"},
	}

func set_action(action) -> void:
	throttle_action = clampf(action["throttle_action"][0], -1.0, 1.0)
	steer_action    = clampf(action["steer_action"][0],    -1.0, 1.0)

	var avg_steer := 0.0
	if _steer_history.size() > 0:
		for entry in _steer_history:
			avg_steer += entry[1]
		avg_steer /= _steer_history.size()

	reward -= absf(steer_action - avg_steer) * STEER_CHANGE_PENALTY
	_steer_history.append([_time_elapsed, steer_action])
