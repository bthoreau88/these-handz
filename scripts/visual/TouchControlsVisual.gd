# G01C touch movement HUD - visual only. Never owns raw input.
# Hit testing, contact state and semantic gesture emission live in GestureInput.
class_name TouchControlsVisual
extends Control

var _solo: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = DisplayServer.is_touchscreen_available() or OS.has_feature("web") \
			or GameConstants.TOUCH_PAD_SHOW_DESKTOP
	GestureInput.movement_state_changed.connect(queue_redraw)
	get_viewport().size_changed.connect(queue_redraw)


func setup(solo: bool) -> void:
	_solo = solo
	queue_redraw()


func _draw() -> void:
	if not is_inside_tree() or get_viewport() == null:
		return
	for player_id in [1, 2]:
		if player_id == 2 and _solo:
			continue
		for direction in ["left", "right"]:
			_draw_button(player_id, direction)


func _draw_button(player_id: int, direction: String) -> void:
	var rect: Rect2 = GestureInput.touch_pad_rect(player_id, direction)
	var accent: Color = Color(0.16, 0.85, 0.77) if player_id == 1 \
			else Color(0.95, 0.73, 0.34)
	var held: bool = GestureInput.is_movement_held(player_id, direction)
	var fill: Color = Color(0.07, 0.13, 0.15, 0.75) if not held \
			else Color(accent.r, accent.g, accent.b, 0.42)
	draw_rect(rect, fill, true)
	draw_rect(rect, accent, false, 3.0)
	var center: Vector2 = rect.get_center()
	var half_width: float = rect.size.x * 0.24
	var half_height: float = rect.size.y * 0.30
	var tip_x: float = center.x - half_width if direction == "left" \
			else center.x + half_width
	var base_x: float = center.x + half_width if direction == "left" \
			else center.x - half_width
	draw_colored_polygon(PackedVector2Array([
		Vector2(tip_x, center.y),
		Vector2(base_x, center.y - half_height),
		Vector2(base_x, center.y + half_height)]), accent)
