# =============================================================================
# GestureInput.gd — gesture recognizer, registered as the "GestureInput"
# autoload singleton. This is the ONLY script in the game that touches raw
# input events (Project Rule 2). It turns touches / keyboard into semantic
# gesture dictionaries and emits them; InputRouter decides which player they
# belong to; CharacterBase turns them into moves.
#
# Emitted gesture dictionary shape:
#   {
#     "device":   "touch" or "keyboard",
#     "position": Vector2 (screen position; Vector2.ZERO for keyboard),
#     "type":     "tap" | "swipe" | "action",
#     "dir":      "left"|"right"|"up"|"down"   (only when type == "swipe"),
#     "action":   "light"|"medium"|"heavy"|"super"|"special_a"|"special_b"|
#                 "block_start"|"block_end"|"block_tap"|"parry"|"charge"|
#                 "walk_left_start"|"walk_left_end"|"walk_right_start"|
#                 "walk_right_end"   (only when type == "action")
#   }
#
# Touch mapping (bible §05 — NO quarter-circles):
#   1-finger tap            -> tap (light attack)
#   1-finger swipe          -> swipe with direction (character maps by facing)
#   swipe ← then → quickly  -> action special_a
#   swipe ↓ then → quickly  -> action special_b
#   1-finger hold           -> action charge
#   2-finger tap            -> action block_tap (timed block)
#   2-finger swipe          -> action parry
#
# Keyboard fallback for desktop testing (controls Player 1 only):
#   Z=light  X=medium  C=heavy  V=super  A=SpecialA  S=SpecialB
#   D=block (hold)  F=parry
# =============================================================================
extends Node

signal gesture_detected(gesture: Dictionary)

# Active touches, keyed by touch index.
# Each record: {start_pos, start_time_ms, fingers_at_press, consumed}
var _touches: Dictionary = {}

# Last completed 1-finger swipe, used to detect ←→ / ↓→ sequences.
# {dir: String, time_ms: int, side: String("left"/"right" half of screen)}
var _last_swipe: Dictionary = {}


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		_handle_key(event)
	elif event is InputEventScreenTouch:
		_handle_touch(event)
	# InputEventScreenDrag is ignored on purpose: we classify a gesture from
	# its press and release points, which is cheaper and good enough for now.


# --- Keyboard fallback ------------------------------------------------------
func _handle_key(event: InputEventKey) -> void:
	if event.echo:
		return

	# Held keys emit a _start on press and an _end on release.
	# D = block; arrow keys = walk (desktop testing only — touch movement
	# comes with the Phase 2 mobile pass).
	match event.keycode:
		KEY_D:
			_emit_action("block_start" if event.pressed else "block_end", "keyboard", Vector2.ZERO)
			return
		KEY_LEFT:
			_emit_action("walk_left_start" if event.pressed else "walk_left_end", "keyboard", Vector2.ZERO)
			return
		KEY_RIGHT:
			_emit_action("walk_right_start" if event.pressed else "walk_right_end", "keyboard", Vector2.ZERO)
			return

	if not event.pressed:
		return

	match event.keycode:
		KEY_Z:
			_emit_action("light", "keyboard", Vector2.ZERO)
		KEY_X:
			_emit_action("medium", "keyboard", Vector2.ZERO)
		KEY_C:
			_emit_action("heavy", "keyboard", Vector2.ZERO)
		KEY_V:
			_emit_action("super", "keyboard", Vector2.ZERO)
		KEY_A:
			_emit_action("special_a", "keyboard", Vector2.ZERO)
		KEY_S:
			_emit_action("special_b", "keyboard", Vector2.ZERO)
		KEY_F:
			_emit_action("parry", "keyboard", Vector2.ZERO)
		KEY_Q:
			# Desktop stand-in for touch hold-to-charge (Coat Catch,
			# Deadpan Charge, Bucket Counter, Scarf Snare...).
			_emit_action("charge", "keyboard", Vector2.ZERO)


# --- Touch recognition ------------------------------------------------------
func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touches[event.index] = {
			"start_pos": event.position,
			"start_time_ms": Time.get_ticks_msec(),
			"fingers_at_press": _touches.size() + 1,
			"consumed": false,
		}
		return

	# Finger lifted.
	if not _touches.has(event.index):
		return
	var record: Dictionary = _touches[event.index]
	_touches.erase(event.index)
	if record["consumed"]:
		return

	var duration_ms: int = Time.get_ticks_msec() - record["start_time_ms"]
	var travel: Vector2 = event.position - record["start_pos"]
	var is_swipe: bool = travel.length() >= GameConstants.SWIPE_MIN_DISTANCE_PX

	# Two fingers on screen when this one pressed -> block or parry.
	if record["fingers_at_press"] >= 2 or _touches.size() >= 1:
		_consume_remaining_touches()
		if is_swipe:
			_emit_action("parry", "touch", record["start_pos"])
		else:
			_emit_action("block_tap", "touch", record["start_pos"])
		return

	if is_swipe:
		_classify_swipe(travel, record["start_pos"])
	elif duration_ms >= GameConstants.HOLD_MIN_DURATION_MS:
		_emit_action("charge", "touch", record["start_pos"])
	elif duration_ms <= GameConstants.TAP_MAX_DURATION_MS \
			and travel.length() <= GameConstants.TAP_MAX_DISTANCE_PX:
		gesture_detected.emit({
			"device": "touch",
			"position": record["start_pos"],
			"type": "tap",
		})


# Mark every still-held touch as consumed so a 2-finger gesture fires once,
# not once per finger.
func _consume_remaining_touches() -> void:
	for index in _touches:
		_touches[index]["consumed"] = true


func _classify_swipe(travel: Vector2, start_pos: Vector2) -> void:
	var dir: String
	if absf(travel.x) >= absf(travel.y):
		dir = "right" if travel.x > 0.0 else "left"
	else:
		dir = "down" if travel.y > 0.0 else "up"

	var side := "left" if start_pos.x < _half_screen_x() else "right"
	var now_ms := Time.get_ticks_msec()

	# Sequence specials: ← then →  = Special A;  ↓ then →  = Special B.
	# TODO(roadmap: polish): mirror these by facing so P2 does →← / ↓←.
	if dir == "right" and not _last_swipe.is_empty() and _last_swipe["side"] == side \
			and now_ms - _last_swipe["time_ms"] <= GameConstants.SPECIAL_SEQUENCE_WINDOW_MS:
		if _last_swipe["dir"] == "left":
			_last_swipe = {}
			_emit_action("special_a", "touch", start_pos)
			return
		if _last_swipe["dir"] == "down":
			_last_swipe = {}
			_emit_action("special_b", "touch", start_pos)
			return

	_last_swipe = {"dir": dir, "time_ms": now_ms, "side": side}
	gesture_detected.emit({
		"device": "touch",
		"position": start_pos,
		"type": "swipe",
		"dir": dir,
	})


func _emit_action(action: String, device: String, position: Vector2) -> void:
	gesture_detected.emit({
		"device": device,
		"position": position,
		"type": "action",
		"action": action,
	})


func _half_screen_x() -> float:
	return get_viewport().get_visible_rect().size.x * 0.5
