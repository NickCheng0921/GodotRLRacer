class_name CarPathRaySensor3D
extends Node3D

@export var max_range: float = 100.0
@export var coarse_step: float = 4.0   # march step to find the edge bracket
@export var refine_iterations: int = 6  # binary search within bracket (~coarse_step / 2^6 precision)
@export var ray_down_length: float = 6.0
@export var debug_draw: bool = true
@export var color_on_road: Color = Color(0.2, 0.9, 0.2)
@export var color_edge: Color = Color(1.0, 0.3, 0.1)

# Angles relative to car forward (+X). Positive = clockwise from above.
# [forward, forward-left, forward-right, left, right]
const RAY_ANGLES_DEG: Array[float] = [0.0, -45.0, 45.0, -90.0, 90.0]

const ROAD_LAYER := 2

var distances: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]

var _space_state: PhysicsDirectSpaceState3D
var _mesh_instance: MeshInstance3D
var _imesh: ImmediateMesh


func _ready() -> void:
	_imesh = ImmediateMesh.new()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _imesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)


func _physics_process(_delta: float) -> void:
	_space_state = get_world_3d().direct_space_state
	_update_rays()
	if debug_draw:
		_draw_debug()


func _update_rays() -> void:
	var forward := global_transform.basis.x
	for i in RAY_ANGLES_DEG.size():
		var dir := forward.rotated(Vector3.UP, deg_to_rad(RAY_ANGLES_DEG[i]))
		distances[i] = _find_edge(global_position, dir)


# Adaptive march: small steps near the car growing to coarse_step at distance.
# Catches near edges that a fixed coarse step would skip, then refines with
# binary search once the bracket is found.
func _find_edge(origin: Vector3, direction: Vector3) -> float:
	var lo := 0.0
	var travelled := 0.0
	while travelled < max_range:
		var step := minf(coarse_step, maxf(1.0, travelled * 0.2))
		travelled = minf(travelled + step, max_range)
		if not _is_on_road(origin + direction * travelled):
			return _refine(origin, direction, lo, travelled)
		lo = travelled
	return max_range


func _refine(origin: Vector3, direction: Vector3, lo: float, hi: float) -> float:
	for _i in refine_iterations:
		var mid := (lo + hi) * 0.5
		if _is_on_road(origin + direction * mid):
			lo = mid
		else:
			hi = mid
	return lo


func _is_on_road(world_pos: Vector3) -> bool:
	var from := world_pos + Vector3.UP * 1.0
	var to   := world_pos + Vector3.DOWN * ray_down_length
	var query := PhysicsRayQueryParameters3D.create(from, to, ROAD_LAYER)
	query.collide_with_areas = true
	return not _space_state.intersect_ray(query).is_empty()


func _draw_debug() -> void:
	_imesh.clear_surfaces()
	_imesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var forward := global_transform.basis.x
	for i in RAY_ANGLES_DEG.size():
		var dir := forward.rotated(Vector3.UP, deg_to_rad(RAY_ANGLES_DEG[i]))
		var d := distances[i]
		var end_world := global_position + dir * d
		var col := color_on_road if d >= max_range else color_edge
		_imesh.surface_set_color(col)
		_imesh.surface_add_vertex(to_local(global_position))
		_imesh.surface_set_color(col)
		_imesh.surface_add_vertex(to_local(end_world))
	_imesh.surface_end()


# Returns values normalized to [0, 1]. Append directly into get_obs().
func get_observations() -> Array[float]:
	var obs: Array[float] = []
	for d in distances:
		obs.append(clampf(d / max_range, 0.0, 1.0))
	return obs
