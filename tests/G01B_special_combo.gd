# G01B gameplay-path proof: two-swipe special B is not just recognized;
# it must actually execute after the first swipe starts a low attack.
extends SceneTree

var issues: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _assert(label: String, ok: bool) -> void:
	print("G01B_COMBAT ", "PASS " if ok else "FAIL ", label)
	if not ok:
		issues.append(label)

func _run() -> void:
	Roster.pick_p1 = "yellow_dog"
	Roster.pick_p2 = "sol_tigre"
	Roster.p2_is_cpu = true
	Roster.ai_difficulty = "DUMMY"
	var arena = load("res://scenes/FightScene.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await process_frame
	arena.input_router.set_routing_enabled(true)
	var p1: CharacterBase = arena.player1
	var gi = root.get_node("GestureInput")
	gi._last_swipe = {}
	gi._classify_swipe(Vector2(0, 95), Vector2(140, 250))
	_assert("down swipe begins low attack", p1.get_attack_name() == "low")
	gi._classify_swipe(Vector2(95, 0), Vector2(140, 250))
	_assert("special B queued during preceding low attack", p1._buffered_special == "special_b")
	for i in range(GameConstants.SPECIAL_INPUT_BUFFER_FRAMES + 2):
		await physics_frame
	_assert("down right combo executes special B after low recovery", p1.modulate.a < 0.5)
	print("G01B_COMBAT_FAILED=", issues.size())
	quit(0 if issues.is_empty() else 1)
