extends Control

var car: RigidBody3D

const MAX_G    := 4.0  # outer ring = 4G, dot clamps to ring
const GRAVITY  := 9.8
const SMOOTH   := 0.25

var _lateral_g: float = 0.0
var _longitudinal_g: float = 0.0
var _prev_velocity: Vector3 = Vector3.ZERO


func _process(delta: float) -> void:
	if not is_instance_valid(car):
		return
	var accel := (car.linear_velocity - _prev_velocity) / delta
	_prev_velocity = car.linear_velocity

	var forward := car.global_transform.basis.x
	var right   := -car.global_transform.basis.z

	_longitudinal_g = lerpf(_longitudinal_g, accel.dot(forward) / GRAVITY, SMOOTH)
	_lateral_g      = lerpf(_lateral_g,      accel.dot(right)   / GRAVITY, SMOOTH)
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 * 0.78
	var font   := ThemeDB.fallback_font
	var col_orange := Color(0.85, 0.4, 0.0)
	var col_out    := Color(0.0, 0.0, 0.0, 0.9)

	# Background
	draw_circle(center, radius, Color(0.08, 0.08, 0.08, 0.88))

	# Rings at 1G and 2G, outer border at 4G
	var ring_gs := [1.0, 2.0]
	for g in ring_gs:
		var r : float = radius * (g / MAX_G)
		draw_arc(center, r, 0.0, TAU, 64, Color(0.85, 0.4, 0.0, 0.55), 1.0)
		# Ring label at top of each ring
		var label := "%dG" % int(g)
		var lpos  := center + Vector2(-8, -r + 12)
		draw_string_outline(font, lpos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, col_out)
		draw_string(font, lpos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col_orange)
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.85, 0.4, 0.0, 0.9), 1.5)
	# Outer ring label
	var lpos4 := center + Vector2(-10, -radius + 12)
	draw_string_outline(font, lpos4, "4G", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, col_out)
	draw_string(font, lpos4, "4G", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col_orange)

	# Crosshair
	var col_line := Color(0.85, 0.4, 0.0, 0.5)
	draw_line(Vector2(center.x - radius, center.y), Vector2(center.x + radius, center.y), col_line, 1.0)
	draw_line(Vector2(center.x, center.y - radius), Vector2(center.x, center.y + radius), col_line, 1.0)

	# Direction labels + actual G readouts
	var col_num := Color(1.0, 1.0, 1.0)
	var labels  := [
		[Vector2(center.x - 16, center.y - radius - 3),  "ACCEL", 12, col_orange],
		[Vector2(center.x - 16, center.y + radius + 14), "BRAKE", 12, col_orange],
		[Vector2(2,              center.y + 5),           "LEFT",  12, col_orange],
		[Vector2(size.x - 30,   center.y + 5),           "RIGHT", 12, col_orange],
		# Actual (unclamped) values
		[Vector2(center.x - 12, center.y - radius + 26), "%.2f" % absf(_longitudinal_g), 13, col_num],
		[Vector2(center.x - 12, center.y + radius - 3),  "%.2f" % absf(_longitudinal_g), 13, col_num],
		[Vector2(4,              center.y - 9),           "%.2f" % absf(_lateral_g),      13, col_num],
		[Vector2(size.x - 36,   center.y - 9),           "%.2f" % absf(_lateral_g),      13, col_num],
	]
	for l in labels:
		draw_string_outline(font, l[0], l[1], HORIZONTAL_ALIGNMENT_LEFT, -1, l[2], 4, col_out)
		draw_string(font, l[0], l[1], HORIZONTAL_ALIGNMENT_LEFT, -1, l[2], l[3])

	# Dot — clamped to radius visually, values still show real G
	var raw := Vector2(_lateral_g, -_longitudinal_g)
	var dot_offset := raw / MAX_G * radius
	if dot_offset.length() > radius:
		dot_offset = dot_offset.normalized() * radius
	draw_circle(center + dot_offset, 5.0, Color(1.0, 0.25, 0.0))
