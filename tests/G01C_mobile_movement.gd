# THESE HANDZ G01C: touch pads + backdash, through GestureInput/InputRouter.
# Headless regression only; physical touchscreen comfort requires human QA.
extends SceneTree

var failures: Array[String] = []
var events: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(label: String, ok: bool) -> void:
	print("G01C ", "PASS " if ok else "FAIL ", label)
	if not ok:
		failures.append(label)

func _capture(event: Dictionary) -> void:
	events.append(event.duplicate())

func _touch(index: int, pos: Vector2, down: bool, gi: Node) -> void:
	var evt := InputEventScreenTouch.new()
	evt.index = index
	evt.position = pos
	evt.pressed = down
	gi._handle_touch(evt)

func _tap(index: int, pos: Vector2, gi: Node) -> void:
	_touch(index, pos, true, gi)
	gi._touches[index]["start_time_ms"] = Time.get_ticks_msec() - 80
	_touch(index, pos, false, gi)

func _run() -> void:
	Roster.pick_p1 = "sol_tigre"
	Roster.pick_p2 = "yellow_dog"
	Roster.p2_is_cpu = false
	var arena: Node2D = load("res://scenes/FightScene.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await process_frame
	var p1: CharacterBase = arena.player1
	var p2: CharacterBase = arena.player2
	var gi: Node = root.get_node("GestureInput")
	gi.gesture_detected.connect(_capture)
	var ui: Control = arena.get_node("TouchControlsLayer/MovementButtons")
	_check("visual touch layer exists and ignores pointers", ui != null and ui.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	_check("movement zones activate in a fight", gi._movement_enabled)
	_check("two human fighters see both pad sets", not gi._solo_movement and not ui._solo)
	_check("compatibility renderer selected", ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility")
	var p1_left: Vector2 = gi.touch_pad_rect(1, "left").get_center()
	var p1_right: Vector2 = gi.touch_pad_rect(1, "right").get_center()
	var p2_left: Vector2 = gi.touch_pad_rect(2, "left").get_center()
	var p2_right: Vector2 = gi.touch_pad_rect(2, "right").get_center()
	_check("pad rectangles are disjoint", not gi.touch_pad_rect(1, "left").intersects(gi.touch_pad_rect(1, "right")) and not gi.touch_pad_rect(1, "right").intersects(gi.touch_pad_rect(2, "left")))
	# Countdown forbids both keyboard and virtual-pad input.
	_check("countdown begins with routing off", not arena.input_router._routing_enabled)
	_touch(0, p1_left, true, gi)
	_check("pad start ignored during countdown", p1._walk_input == 0)
	_touch(0, p1_left, false, gi)
	arena.input_router.set_routing_enabled(true)
	var event_count: int = events.size()
	_touch(0, p1_left, true, gi)
	_check("P1 left pad generates semantic walk start", p1._walk_input == -1)
	var x_before: float = p1.global_position.x
	for i in range(10):
		await physics_frame
	_check("P1 moves left continuously", p1.global_position.x < x_before - 5.0)
	# Pad finger excluded from attack-finger count; attack works simultaneously.
	_tap(1, Vector2(470, 260), gi)
	_check("attack tap works while movement is held", p1.state == CharacterBase.FightState.ATTACKING and p1._walk_input == -1)
	_check("held pad does not cause false two-finger block", events.slice(event_count).any(func(e): return e.get("type") == "tap") and not events.slice(event_count).any(func(e): return e.get("action", "") == "block_tap"))
	_touch(0, p1_left, false, gi)
	_check("pad release clears movement without attack", p1._walk_input == 0 and gi._movement_touches.is_empty())
	# Held direction during attack is retained as intent and resumes on recovery.
	p1.reset_for_round()
	p2.reset_for_round()
	_tap(1, Vector2(470, 260), gi)
	_touch(0, p1_right, true, gi)
	_check("walk intent retained while fighter attacks", p1._walk_input == 1 and p1.state == CharacterBase.FightState.ATTACKING)
	var from_attack: float = p1.global_position.x
	for i in range(35):
		await physics_frame
	_check("walking resumes after attack recovery", p1.global_position.x > from_attack + 3.0)
	_touch(0, p1_right, false, gi)
	_check("P1 movement stops on finger lift", p1._walk_input == 0)
	_touch(2, p2_right, true, gi)
	_check("P2 right pad routes to P2 only", p2._walk_input == 1 and p1._walk_input == 0)
	_touch(2, p2_right, false, gi)
	_check("P2 movement release clears state", p2._walk_input == 0)
	# Conflicting second movement finger cannot strand the primary state.
	_touch(0, p1_left, true, gi)
	_touch(1, p1_right, true, gi)
	_check("opposed simultaneous pad contacts cannot invert walk", p1._walk_input == -1)
	_touch(1, p1_right, false, gi)
	_touch(0, p1_left, false, gi)
	_check("opposed pad releases do not stick movement", p1._walk_input == 0)
	# Backdash from an outward swipe in the regular gesture area.
	p1.reset_for_round()
	p1.facing = 1
	gi._last_swipe = {}
	gi._classify_swipe(Vector2(-120, 0), Vector2(465, 260))
	_check("P1 outward swipe starts backdash", p1._dash_frames > 0 and p1._dash_direction == -1 and p1._dash_speed == GameConstants.BACKDASH_SPEED)
	var back_start: float = p1.global_position.x
	for i in range(5):
		await physics_frame
	_check("P1 backdash moves away", p1.global_position.x < back_start - 4.0)
	p2.reset_for_round()
	p2.facing = -1
	gi._last_swipe = {}
	gi._classify_swipe(Vector2(120, 0), Vector2(900, 260))
	_check("P2 outward swipe starts rightward backdash", p2._dash_frames > 0 and p2._dash_direction == 1)
	# In solo mode the unowned right pad is not a movement zone.
	gi.configure_movement(true, true)
	_check("solo mode removes right-side P2 movement zone", gi._movement_zone(p2_left).is_empty())
	gi.configure_movement(true, false)
	_touch(0, p1_right, true, gi)
	arena.queue_free()
	current_scene = null
	await process_frame
	_check("scene exit disables movement and clears contacts", not gi._movement_enabled and gi._movement_touches.is_empty())
	print("G01C_TOTAL_FAILURES=", failures.size())
	quit(0 if failures.is_empty() else 1)
