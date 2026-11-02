# THESE HANDZ G01A — isolated deterministic integration tests (NOT phone QA).
extends SceneTree

var failures: Array[String] = []
var winner_id: int = -1

func _initialize() -> void:
	Engine.time_scale = 10.0
	call_deferred("_run")

func _check(name: String, passed: bool) -> void:
	print("G01A ", "PASS " if passed else "FAIL ", name)
	if not passed:
		failures.append(name)

func _match_ended(winner: int) -> void:
	winner_id = winner

func _until_active(arena: Node2D, round_no: int, max_frames: int = 1200) -> bool:
	for i in range(max_frames):
		if arena.round_manager._round_number == round_no and arena.round_manager._fighting:
			return true
		await physics_frame
	return false

func _until_match_ended(max_frames: int = 600) -> bool:
	for i in range(max_frames):
		if winner_id != -1:
			return true
		await physics_frame
	return false

func _emit_light() -> void:
	root.get_node("GestureInput").gesture_detected.emit({
		"type": "tap", "device": "keyboard", "position": Vector2.ZERO
	})

func _run() -> void:
	Roster.pick_p1 = "sol_tigre"
	Roster.pick_p2 = "yellow_dog"
	Roster.p2_is_cpu = false
	var arena = load("res://scenes/FightScene.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await process_frame
	var p1: CharacterBase = arena.player1
	var p2: CharacterBase = arena.player2
	var rm = arena.round_manager
	rm.match_ended.connect(_match_ended)
	_check("round input disabled during countdown", not rm._fighting)
	_emit_light()
	_check("early input does not cause attack", p1.state == CharacterBase.FightState.IDLE)
	var active: bool = await _until_active(arena, 1)
	_check("first countdown reaches live combat", active)
	if not active:
		_finish()
		return
	p1.global_position = Vector2(820, 560)
	p2.global_position = Vector2(905, 560)
	await physics_frame
	var old_hp: float = p2.health
	_emit_light()
	_check("live gesture starts light attack", p1.state == CharacterBase.FightState.ATTACKING)
	for i in range(26):
		await physics_frame
	_check("live hit reduces opponent health", p2.health < old_hp)
	p1.meter.add(GameConstants.METER_MAX)
	_check("meter fills through public meter API", is_equal_approx(p1.meter.value, GameConstants.METER_MAX))
	p2.take_hit(GameConstants.MAX_HEALTH * 2.0, p1, 10)
	_check("KO scores round one", rm._wins[1] == 1 and not rm._fighting)
	var active2: bool = await _until_active(arena, 2)
	_check("KO advances to round two", active2)
	if not active2:
		_finish()
		return
	_check("P1 health reset after round transition", is_equal_approx(p1.health, GameConstants.MAX_HEALTH))
	_check("meter carries half between rounds", is_equal_approx(p1.meter.value, GameConstants.METER_MAX * GameConstants.METER_ROUND_CARRY))
	# Time-out winner path: leave P1 with more health and expire clock.
	p2.take_hit(75.0, p1, 1)
	rm._time_left = 0.00001
	var ended: bool = await _until_match_ended()
	_check("time-out scores second round", rm._wins[1] == 2 and not rm._fighting)
	_check("best-of-three ends with P1 winner", ended and winner_id == 1)
	# Prevent the match-end async UI callback from changing scenes during second test.
	arena.queue_free()
	current_scene = null
	await process_frame
	Roster.p2_is_cpu = true
	Roster.ai_difficulty = "NORMAL"
	var solo = load("res://scenes/FightScene.tscn").instantiate()
	root.add_child(solo)
	current_scene = solo
	await process_frame
	var cpu: CharacterBase = solo.player2
	var cpu_brain = cpu.get_node_or_null("AIController")
	_check("CPU opponent is attached", cpu_brain != null)
	var start_x: float = cpu.global_position.x
	var moved_early: bool = false
	for i in range(55):
		await physics_frame
		# Only sample behavior while countdown is active; time_scale accelerates it.
		if solo.round_manager._fighting:
			break
		if absf(cpu.global_position.x - start_x) > 0.5 or cpu._walk_input != 0 or cpu._dash_frames > 0:
			moved_early = true
	_check("CPU waits until FIGHT countdown finishes", not moved_early)
	var cpu_round_active: bool = await _until_active(solo, 1)
	_check("CPU match countdown reaches FIGHT", cpu_round_active)
	if cpu_round_active:
		var live_start_x: float = cpu.global_position.x
		for j in range(65):
			await physics_frame
		_check("CPU engages once round is live", absf(cpu.global_position.x - live_start_x) > 1.0 or cpu._walk_input != 0 or cpu._dash_frames > 0)
	_finish()

func _finish() -> void:
	print("G01A_TOTAL_FAILURES=", failures.size())
	Engine.time_scale = 1.0
	quit(0 if failures.is_empty() else 1)
