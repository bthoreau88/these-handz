# THESE HANDZ / OVS — G01 repeatable runtime smoke test
# Run: godot --headless --path . --script res://tests/G01_runtime_smoke.gd
# This test does not alter combat tuning, roster, or production art.
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(label: String, ok: bool) -> void:
	print("G01 ", "PASS " if ok else "FAIL ", label)
	if not ok:
		failures.append(label)

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
	_check("fight scene creates both chosen fighters", p1 != null and p2 != null)
	_check("fighters start at full health", p1.health == GameConstants.MAX_HEALTH and p2.health == GameConstants.MAX_HEALTH)
	_check("fighters have meter and parry", p1.meter != null and p2.meter != null and p1.parry != null)
	_check("input router knows both fighters", arena.input_router._player1 == p1 and arena.input_router._player2 == p2)
	_check("round manager starts countdown", arena.round_manager._round_number == 1)
	# Exercise the real GestureInput signal and InputRouter; do not call start_attack directly.
	p1.global_position = Vector2(565, 560)
	p2.global_position = Vector2(650, 560)
	await physics_frame
	arena.input_router.set_routing_enabled(true)
	var old_hp: float = p2.health
	root.get_node("GestureInput").gesture_detected.emit({"type": "tap", "device": "keyboard", "position": Vector2.ZERO})
	_check("keyboard gesture enters ATTACKING state", p1.state == CharacterBase.FightState.ATTACKING)
	for frame in range(28):
		await physics_frame
	_check("active-frame hit damages second fighter", p2.health < old_hp)
	_check("HUD updates from health signal", arena.health_bar_p2.value == p2.health)
	_check("stage background integrated", arena.get_node_or_null("StageBackground") != null)
	_check("fighting camera integrated", arena.get_node_or_null("FightCamera") != null)
	var roster_ok: bool = true
	for fighter_id in Roster.FIGHTERS.keys():
		var packed: PackedScene = Roster.load_fighter_scene(fighter_id)
		if packed == null:
			roster_ok = false
			continue
		var fighter: CharacterBase = packed.instantiate()
		fighter.position = Vector2(400, 560)
		root.add_child(fighter)
		await process_frame
		if fighter.meter == null or fighter.parry == null:
			roster_ok = false
		fighter.queue_free()
		await process_frame
	_check("all eight roster fighter scenes instantiate", roster_ok)
	print("G01_TOTAL_FAILURES=", failures.size())
	quit(1 if not failures.is_empty() else 0)
