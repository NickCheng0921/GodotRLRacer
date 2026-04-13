extends Node3D


func _ready() -> void:
	_setup_topdown_viewport()

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
