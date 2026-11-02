# THESE HANDZ — G01B gesture recognizer evidence test.
# Exercises Input.parse_input_event -> GestureInput autoload, not combat stubs.
extends SceneTree

var captured: Array[Dictionary] = []
var failed: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _capture(g: Dictionary) -> void:
	captured.append(g.duplicate())

func _assert(label: String, condition: bool) -> void:
	print("G01B ", "PASS " if condition else "FAIL ", label)
	if not condition:
		failed.append(label)

func _event(index: int, position: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = position
	e.pressed = down
	Input.parse_input_event(e)
	await process_frame

func _expect_action(a: String) -> bool:
	return not captured.is_empty() and captured.back().get("type") == "action" and captured.back().get("action") == a

func _expect_swipe(direction: String) -> bool:
	return not captured.is_empty() and captured.back().get("type") == "swipe" and captured.back().get("dir") == direction

func _one_swipe(pos: Vector2, shift: Vector2) -> void:
	await _event(0, pos, true)
	await _event(0, pos + shift, false)

func _run() -> void:
	var gi = root.get_node("GestureInput")
	gi.gesture_detected.connect(_capture)
	# Give Godot time to register autoload input callbacks before injection.
	await process_frame
	await process_frame
	await _event(0, Vector2(140, 300), true)
	# Make the synthetic tap's press duration explicit; headless startup can stall.
	gi._touches[0]["start_time_ms"] = Time.get_ticks_msec() - 80
	# Headless viewport scales injected screen coordinates; keep physical drift tiny.
	await _event(0, Vector2(140.2, 300.1), false)
	_assert("one finger tap", not captured.is_empty() and captured.back().get("type") == "tap")
	for dir in [{"label":"left", "shift":Vector2(-100,0)},{"label":"right","shift":Vector2(100,0)},{"label":"up","shift":Vector2(0,-100)},{"label":"down","shift":Vector2(0,100)}]:
		gi._last_swipe = {}
		await _one_swipe(Vector2(300, 250), dir["shift"])
		_assert("one finger "+dir["label"]+" swipe", _expect_swipe(dir["label"]))
	await _event(0, Vector2(240, 250), true)
	gi._touches[0]["start_time_ms"] -= GameConstants.HOLD_MIN_DURATION_MS + 20
	await _event(0, Vector2(240, 250), false)
	_assert("long press produces charge", _expect_action("charge"))
	var before_two: int = captured.size()
	await _event(0, Vector2(155, 250), true)
	await _event(1, Vector2(245, 250), true)
	await _event(0, Vector2(155, 250), false)
	await _event(1, Vector2(245, 250), false)
	_assert("two finger block fires exactly once", captured.size() == before_two+1 and _expect_action("block_tap"))
	var before_parry: int = captured.size()
	await _event(0, Vector2(155, 250), true)
	await _event(1, Vector2(245, 250), true)
	await _event(1, Vector2(315, 250), false)
	await _event(0, Vector2(155, 250), false)
	_assert("two finger parry fires exactly once", captured.size() == before_parry+1 and _expect_action("parry"))
	gi._last_swipe = {}
	await _one_swipe(Vector2(320,250), Vector2(-105,0))
	await _one_swipe(Vector2(320,250), Vector2(105,0))
	_assert("left right special A", _expect_action("special_a"))
	gi._last_swipe = {}
	await _one_swipe(Vector2(320,250), Vector2(0,95))
	await _one_swipe(Vector2(320,250), Vector2(105,0))
	_assert("down right special B", _expect_action("special_b"))
	gi._last_swipe = {}
	await _one_swipe(Vector2(950,250), Vector2(105,0))
	await _one_swipe(Vector2(950,250), Vector2(-105,0))
	_assert("P2-facing-left mirrored special A", _expect_action("special_a"))
	gi._last_swipe = {}
	await _one_swipe(Vector2(950,250), Vector2(0,95))
	await _one_swipe(Vector2(950,250), Vector2(-105,0))
	_assert("P2-facing-left mirrored special B", _expect_action("special_b"))
	_assert("touches cleared after completed gestures", gi._touches.is_empty())
	print("G01B_GESTURE_FAILED=", failed.size())
	quit(0 if failed.is_empty() else 1)
