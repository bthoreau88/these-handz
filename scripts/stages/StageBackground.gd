# =============================================================================
# StageBackground.gd — the parallax backdrop behind a fight.
#
# Builds one ParallaxLayer per entry in GameConstants.STAGE_LAYERS, back to
# front. Each layer's `scroll` decides how much it drifts with the camera:
# 0.0 reads as infinitely far away, 1.0 is locked to the world like the floor.
# That difference is what sells depth as the camera tracks the fighters.
#
# ART IS OPTIONAL. Any layer whose PNG is missing is quietly replaced by a
# procedural stand-in (gradient sky, blocky skyline silhouettes), so the stage
# looks intentional from day one and each real layer can drop in one at a time
# without ever leaving a hole.
#
# TO ADD REAL ART: drop sky.png / far.png / mid.png / near.png into the
# stage's `dir` (see GameConstants.STAGES). Nothing here needs editing.
# Bible §06 sizes stages at 640x360 @1x; layers are scaled to the stage's
# playable width, so author them wider than tall.
#
# Godot note (ParallaxBackground): it reads the active Camera2D automatically
# and shifts each child ParallaxLayer by its motion_scale. We never move these
# nodes ourselves.
# =============================================================================
class_name StageBackground
extends ParallaxBackground

const SKYLINE_SEED := 20260731   # fixed so the placeholder never flickers

var _stage: Dictionary = {}


func setup(stage_id: String) -> void:
	_stage = GameConstants.STAGES.get(stage_id, GameConstants.STAGES[GameConstants.DEFAULT_STAGE])
	for child in get_children():
		child.queue_free()
	for index in GameConstants.STAGE_LAYERS.size():
		_build_layer(index, GameConstants.STAGE_LAYERS[index])


func _build_layer(index: int, spec: Dictionary) -> void:
	var layer := ParallaxLayer.new()
	layer.name = "Layer%d" % index
	# motion_scale 0 pins a layer to the screen; 1 moves it with the world.
	layer.motion_scale = Vector2(spec["scroll"], spec["scroll"] * 0.35)
	add_child(layer)

	var path: String = "%s/%s" % [_stage["dir"], spec["file"]]
	if ResourceLoader.exists(path):
		_add_art(layer, load(path))
	else:
		_add_placeholder(layer, index)


func _add_art(layer: ParallaxLayer, texture: Texture2D) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	# Scale the art to cover the playable width, keeping its aspect ratio.
	var size: Vector2 = texture.get_size()
	if size.x > 0.0:
		var fit: float = GameConstants.STAGE_PLAY_WIDTH / size.x
		sprite.scale = Vector2(fit, fit)
		# Sit the art so its bottom edge meets the ground line.
		sprite.position = Vector2(0.0, GameConstants.STAGE_GROUND_Y - size.y * fit)
	layer.add_child(sprite)


# --- Procedural stand-ins ----------------------------------------------------
func _add_placeholder(layer: ParallaxLayer, index: int) -> void:
	match index:
		0:
			_add_sky(layer)
		_:
			_add_skyline(layer, index)


func _add_sky(layer: ParallaxLayer) -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, _stage["sky_top"])
	gradient.set_color(1, _stage["sky_bottom"])

	var fill := GradientTexture2D.new()
	fill.gradient = gradient
	fill.fill_from = Vector2(0.0, 0.0)
	fill.fill_to = Vector2(0.0, 1.0)
	fill.width = 8
	fill.height = 256

	var sprite := Sprite2D.new()
	sprite.texture = fill
	sprite.centered = false
	# Overscan generously: a near-static layer must still cover the screen
	# when the camera pans and zooms out.
	sprite.scale = Vector2(GameConstants.STAGE_PLAY_WIDTH * 2.0 / 8.0, 1000.0 / 256.0)
	sprite.position = Vector2(-GameConstants.STAGE_PLAY_WIDTH * 0.5, -300.0)
	layer.add_child(sprite)


# Blocky city silhouettes — denser and darker the closer the layer is.
func _add_skyline(layer: ParallaxLayer, index: int) -> void:
	var tints: Array = [_stage["far_tint"], _stage["far_tint"],
			_stage["mid_tint"], _stage["near_tint"]]
	var color: Color = tints[mini(index, tints.size() - 1)]

	var rng := RandomNumberGenerator.new()
	rng.seed = SKYLINE_SEED + index

	var width_scale: float = 1.0 + float(index) * 0.35
	var min_height: float = 90.0 * width_scale
	var max_height: float = 260.0 * width_scale

	var x: float = -GameConstants.STAGE_PLAY_WIDTH * 0.5
	var limit: float = GameConstants.STAGE_PLAY_WIDTH * 1.5
	while x < limit:
		var building_width: float = rng.randf_range(70.0, 150.0) * width_scale
		var building_height: float = rng.randf_range(min_height, max_height)
		var block := ColorRect.new()
		block.color = color
		block.size = Vector2(building_width, building_height)
		block.position = Vector2(x, GameConstants.STAGE_GROUND_Y - building_height)
		layer.add_child(block)

		# A few lit windows on the nearer layers so they read as buildings.
		if index >= 2:
			_add_windows(block, rng, color)
		x += building_width + rng.randf_range(12.0, 46.0)


func _add_windows(block: ColorRect, rng: RandomNumberGenerator, base: Color) -> void:
	var lit := base.lightened(0.45)
	lit.a = 0.7
	var step := 26.0
	var row := 22.0
	while row < block.size.y - 14.0:
		var column := 10.0
		while column < block.size.x - 12.0:
			if rng.randf() < 0.45:
				var window := ColorRect.new()
				window.color = lit
				window.size = Vector2(8.0, 11.0)
				window.position = Vector2(column, row)
				block.add_child(window)
			column += step
		row += step * 1.4
