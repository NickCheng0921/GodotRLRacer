extends AIController3D

const MAX_SPEED := 30.0  # m/s, used to normalise speed observation

# continuous -1.0 (full brake) to 1.0 (full throttle), 0 = coast
var throttle_action: float = 0.0
# continuous -1.0 (full left) to 1.0 (full right)
var steer_action: float = 0.0

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
