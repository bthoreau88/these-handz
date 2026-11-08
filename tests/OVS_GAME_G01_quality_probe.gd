# OVS-GAME-G01 — source-aware quality probe. Headless engine checks, NOT device QA.
# Run against isolated G01 review worktree with Godot 4.7:
# godot --headless --path . --script res://tests/OVS_GAME_G01_quality_probe.gd
extends SceneTree

var checks: Array[Dictionary] = []
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(label: String, passed: bool, observation: Variant = null) -> void:
	var item: Dictionary = {"name": label, "passed": passed}
	if observation != null:
		item["observation"] = observation
	checks.append(item)
	print("OVS_GAME_G01 ", "PASS " if passed else "FAIL ", label)
	if not passed:
		failures.append(label)

func _frames(count: int) -> void:
	for _i in range(count):
		await physics_frame

func _tap() -> void:
	# Synthetic keyboard gesture routed through the actual GestureInput signal.
	# This is NOT a sampled physical-touch or input-latency measurement.
	root.get_node("GestureInput").gesture_detected.emit({
		"type": "tap", "device": "keyboard", "position": Vector2.ZERO
	})

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
	_check("roster holds exactly eight configured fighters", Roster.FIGHTERS.size() == 8, Roster.FIGHTERS.size())
	_check("arena has two fighters and a camera", p1 != null and p2 != null and arena.fight_camera != null)
	if p1 == null or p2 == null:
		_finish()
		return

	# Bypass pre-round countdown in this explicitly synthetic probe only.
	arena.input_router.set_routing_enabled(true)
	_tap()
	_check("synthetic light input routes to P1 attack immediately",
			p1.state == CharacterBase.FightState.ATTACKING and p1.get_attack_name() == "light",
			{"physics_frames_from_signal": 0, "synthetic": true})
	await _frames(20)

	# Whiff: hitbox genuinely cannot touch the defender when far away.
	p1.global_position = Vector2(250, 560)
	p2.global_position = Vector2(1650, 560)
	await physics_frame
	var far_health: float = p2.health
	_tap()
	await _frames(21)
	_check("distant light whiffs without damage",
			is_equal_approx(p2.health, far_health),
			{"distance_px_at_setup": 1400.0, "health_before": far_health, "health_after": p2.health})

	# The same signal path must land at close range within active hit frames.
	p1.global_position = Vector2(800, 560)
	p2.global_position = Vector2(920, 560)
	await physics_frame
	var close_health: float = p2.health
	_tap()
	await _frames(21)
	var dealt: float = close_health - p2.health
	_check("close light damages defender", dealt > 0.0,
			{"distance_px_at_setup": 120.0, "damage_observed": dealt})
	_check("HUD tracks defender health after hit",
			is_equal_approx(arena.health_bar_p2.value, p2.health),
			{"hud": arena.health_bar_p2.value, "actual": p2.health})

	# Independent check of the authored parry active-window expiration.
	await _frames(12)
	if p1.can_act():
		p1.receive_gesture({"type": "action", "action": "parry"})
		_check("parry opens authored timing window", p1.parry.is_active(),
				{"window_frames": GameConstants.PARRY_WINDOW_FRAMES})
		await _frames(GameConstants.PARRY_WINDOW_FRAMES + 1)
		_check("unanswered parry window expires", not p1.parry.is_active())
	else:
		_check("fighter recovered before parry probe", false)

	# World edge enforcement: this is isolated from player input/controls.
	p1.global_position.x = -100.0
	await physics_frame
	_check("fighter stays beyond left stage boundary",
			p1.global_position.x >= GameConstants.STAGE_EDGE_MARGIN,
			{"observed_x": p1.global_position.x})
	p1.global_position.x = GameConstants.STAGE_PLAY_WIDTH + 100.0
	await physics_frame
	_check("fighter stays within right stage boundary",
			p1.global_position.x <= GameConstants.STAGE_PLAY_WIDTH - GameConstants.STAGE_EDGE_MARGIN,
			{"observed_x": p1.global_position.x})

	_finish()

func _finish() -> void:
	var report: Dictionary = {
		"gate": "OVS-GAME-G01",
		"engine": Engine.get_version_info().get("string", "unknown"),
		"source_base": "G01B draft review",
		"test_type": "synthetic_headless_engine",
		"phone_tested": false,
		"fps_measured": false,
		"checks": checks,
		"failures": failures,
		"passed": failures.is_empty()
	}
	var path: String = "user://OVS_GAME_G01_quality_probe.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
		print("OVS_GAME_G01_REPORT=", ProjectSettings.globalize_path(path))
	else:
		push_error("Unable to write G01 probe report: " + str(FileAccess.get_open_error()))
		failures.append("report write")
	print("OVS_GAME_G01_FAILURES=", failures.size())
	quit(0 if failures.is_empty() else 1)
