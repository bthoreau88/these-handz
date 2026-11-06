# OVS-GAME-G01 — screen-render capture for an isolated visual changelog.
# Run WITH a display: godot --path . --script res://tools/OVS_GAME_G01_capture.gd
# Never --headless. Outputs to user://, never source assets.
extends SceneTree

var captures: Array[Dictionary] = []
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _capture(arena: Node2D, label: String, pos1: Vector2, pos2: Vector2, dir_abs: String) -> void:
	arena.player1.global_position = pos1
	arena.player2.global_position = pos2
	await physics_frame
	# Snapshot known framing, rather than a historical camera-smoothing position.
	arena.fight_camera.global_position = arena.fight_camera._target_position()
	arena.fight_camera.zoom = Vector2.ONE * arena.fight_camera._target_zoom()
	await RenderingServer.frame_post_draw

	var shot: Image = root.get_texture().get_image()
	if shot == null or shot.is_empty():
		failures.append("missing framebuffer: " + label)
		return
	var file_path: String = dir_abs.path_join(label + ".png")
	var err: Error = shot.save_png(file_path)
	if err != OK:
		failures.append("could not write " + label + ": " + str(err))
		return
	captures.append({
		"name": label,
		"filename": label + ".png",
		"sha256": FileAccess.get_sha256(file_path),
		"size": {"width": shot.get_width(), "height": shot.get_height()},
		"fighters": {"p1": Roster.pick_p1, "p2": Roster.pick_p2},
		"p1_position": {"x": arena.player1.global_position.x, "y": arena.player1.global_position.y},
		"p2_position": {"x": arena.player2.global_position.x, "y": arena.player2.global_position.y},
		"camera_position": {"x": arena.fight_camera.global_position.x, "y": arena.fight_camera.global_position.y},
		"camera_zoom": {"x": arena.fight_camera.zoom.x, "y": arena.fight_camera.zoom.y}
	})
	print("OVS_GAME_G01_CAPTURE=", file_path)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("G01 visual capture requires a rendered display. Do not run --headless.")
		quit(2)
		return
	var dir_abs: String = ProjectSettings.globalize_path("user://OVS_GAME_G01_visual")
	var dir_err: Error = DirAccess.make_dir_recursive_absolute(dir_abs)
	if dir_err != OK:
		push_error("G01 cannot create visual evidence directory: " + str(dir_err))
		quit(2)
		return

	Roster.pick_p1 = "sol_tigre"
	Roster.pick_p2 = "yellow_dog"
	Roster.p2_is_cpu = false
	var arena: Node2D = load("res://scenes/FightScene.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await process_frame
	arena.input_router.set_routing_enabled(false)

	await _capture(arena, "neutral_opening", Vector2(740, 560), Vector2(1180, 560), dir_abs)
	await _capture(arena, "mid_range", Vector2(840, 560), Vector2(1030, 560), dir_abs)
	await _capture(arena, "wide_separation", Vector2(200, 560), Vector2(1720, 560), dir_abs)

	var manifest: Dictionary = {
		"gate": "OVS-GAME-G01",
		"engine": Engine.get_version_info().get("string", "unknown"),
		"display_backend": DisplayServer.get_name(),
		"mode": "live_render_repositioned_fixtures",
		"not_player_test": true,
		"not_performance_test": true,
		"captures": captures,
		"failures": failures
	}
	var manifest_path: String = dir_abs.path_join("manifest.json")
	var file: FileAccess = FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		failures.append("manifest write failed")
	else:
		file.store_string(JSON.stringify(manifest, "\t"))
		file.close()
		print("OVS_GAME_G01_MANIFEST=", manifest_path)
	print("OVS_GAME_G01_CAPTURE_COUNT=", captures.size())
	quit(0 if failures.is_empty() and captures.size() == 3 else 1)
