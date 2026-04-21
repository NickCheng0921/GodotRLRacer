extends Control

var car: Node3D
var cam: Camera3D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(car) or not is_instance_valid(cam):
		return
	var forward := -car.global_transform.basis.z
	var right   :=  car.global_transform.basis.x
	var pos     := car.global_position
	var tip := cam.unproject_position(pos + forward * 3.0)
	var bl  := cam.unproject_position(pos - forward * 2.0 - right * 2.0)
	var br  := cam.unproject_position(pos - forward * 2.0 + right * 2.0)
	draw_colored_polygon(PackedVector2Array([tip, bl, br]), Color(1, 0, 0))
