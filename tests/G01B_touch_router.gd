# G01B — touch-origin routing without synthetic headless viewport scaling.
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _assert(label: String, value: bool) -> void:
	print("G01B_ROUTER ", "PASS " if value else "FAIL ", label)
	if not value:
		failures.append(label)

func _tap(gi: Node, x: float) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = Vector2(x, 300)
	gi._handle_touch(press)
	gi._touches[0]["start_time_ms"] = Time.get_ticks_msec() - 80
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.position = Vector2(x, 300)
	gi._handle_touch(release)

func _run() -> void:
	Roster.pick_p1 = "sol_tigre"
	Roster.pick_p2 = "yellow_dog"
	Roster.p2_is_cpu = false
	var arena = load("res://scenes/FightScene.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await process_frame
	arena.input_router.set_routing_enabled(true)
	var gi = root.get_node("GestureInput")
	var p1: CharacterBase = arena.player1
	var p2: CharacterBase = arena.player2
	_tap(gi, 180.0)
	_assert("left-half touch triggers P1 only", p1.state == CharacterBase.FightState.ATTACKING and p2.state == CharacterBase.FightState.IDLE)
	_tap(gi, 950.0)
	_assert("right-half touch triggers P2", p2.state == CharacterBase.FightState.ATTACKING)
	p1.reset_for_round()
	p2.reset_for_round()
	arena.input_router._single_player = true
	_tap(gi, 950.0)
	_assert("solo match right-side touch routes to P1", p1.state == CharacterBase.FightState.ATTACKING and p2.state == CharacterBase.FightState.IDLE)
	print("G01B_ROUTER_FAILED=", failures.size())
	quit(0 if failures.is_empty() else 1)
