extends Control

var ai

const COL_TRACK  := Color(0.2, 0.2, 0.2)
const COL_ORANGE := Color(0.85, 0.4, 0.0)
const COL_GREEN  := Color(0.2, 0.8, 0.2)
const COL_RED    := Color(0.85, 0.2, 0.2)

func _physics_process(_delta: float) -> void:
	if is_instance_valid(ai):
		queue_redraw()

func _draw() -> void:
	if not is_instance_valid(ai):
		return

	var cx    := size.x * 0.5
	var cy    := size.y * 0.5
	var gap   := 16.0
	var thick := 28.0
	var ht    := thick * 0.5

	var h_len := (cx - gap) * 0.6
	var v_len := (cy - gap) * 0.6

	# Arm backgrounds
	draw_rect(Rect2(cx - gap - h_len, cy - ht, h_len, thick), COL_TRACK)  # left
	draw_rect(Rect2(cx + gap,         cy - ht, h_len, thick), COL_TRACK)  # right
	draw_rect(Rect2(cx - ht, cy - gap - v_len, thick, v_len), COL_TRACK)  # top
	draw_rect(Rect2(cx - ht, cy + gap,         thick, v_len), COL_TRACK)  # bottom

	var steer    := clampf(ai.steer_action,    -1.0, 1.0)
	var throttle := clampf(ai.throttle_action, -1.0, 1.0)

	# Steer: left arm fills rightward from tip, right arm fills leftward from tip
	if steer < 0.0:
		var fw := absf(steer) * h_len
		draw_rect(Rect2(cx - gap - fw, cy - ht, fw, thick), COL_ORANGE)
	elif steer > 0.0:
		var fw := steer * h_len
		draw_rect(Rect2(cx + gap, cy - ht, fw, thick), COL_ORANGE)

	# Throttle: top arm fills downward from tip, bottom arm fills upward from tip
	if throttle > 0.0:
		var fh := throttle * v_len
		draw_rect(Rect2(cx - ht, cy - gap - fh, thick, fh), COL_GREEN)
	elif throttle < 0.0:
		var fh := absf(throttle) * v_len
		draw_rect(Rect2(cx - ht, cy + gap, thick, fh), COL_RED)
