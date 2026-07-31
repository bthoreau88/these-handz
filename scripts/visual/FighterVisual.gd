# =============================================================================
# FighterVisual.gd — the animation puppet for one fighter.
#
# Hangs real drawn body parts on a jointed rig and poses them every frame from
# the fighter's FightState. This is the "puppet-rigged HD anime" pipeline from
# ART_DIRECTION.md: the character is drawn ONCE, cut into parts, and animated
# by rotating joints instead of redrawing frames.
#
# HOW TO GIVE A FIGHTER REAL ART:
#   1. Generate a part-out sheet (see prompts/ART_PROMPTS.md).
#   2. Run:  python3 tools/slice_parts.py <sheet.png> assets/sprites/fighters/<name>
#   3. Set `parts_dir` on this node to that folder. Done — no code changes.
# With no parts_dir (or missing files) it falls back to flat placeholder limbs,
# so a fighter without art still animates.
#
# THE RIG (two-bone limbs, so elbows and knees actually bend):
#   upper_arm -> forearm+hand      thigh -> shin+foot
# Children inherit their parent's rotation, so swinging the upper arm carries
# the forearm with it, exactly like a real arm.
#
# Godot notes:
#  - A Sprite2D draws centered on its node origin. We shift each part with
#    `offset` so the origin lands ON its joint — then rotating the node swings
#    the part around that joint instead of around its middle.
#  - Siblings draw in tree order, so back limbs are added first (behind), then
#    the torso, then front limbs (in front). Cheap, reliable depth.
#  - Layout is computed in the ART's own pixel scale, then the whole rig is
#    scaled down once so the assembled fighter stands SPRITE_BASE_HEIGHT_PX
#    tall in game. Art of any resolution just works.
# =============================================================================
class_name FighterVisual
extends Node2D

# Part files the slicer writes, in rig order.
const PART_NAMES: Array[String] = [
	"head", "torso",
	"upper_arm_front", "forearm_front",
	"upper_arm_back", "forearm_back",
	"thigh_front", "shin_front",
	"thigh_back", "shin_back",
]

# --- Rig proportions, as fractions of each part image ------------------------
# The art is drawn with generous overlap material at each joint, so the joint
# sits slightly INSIDE the image rather than exactly on its edge. Nudge these
# in the Inspector if a fighter's limbs look detached or too deeply inset.
const JOINT_INSET := 0.16    # joint this far down from a limb image's top
const BONE_LENGTH := 0.70    # next joint this far down the same image
const HEAD_PIVOT := 0.88     # head origin this far down the head image (neck)
const SHOULDER_DROP := 0.12  # shoulder this far down from the torso's top
const NECK_DROP := 0.06      # neck this far down from the torso's top

# Folder of sliced part PNGs, e.g. "res://assets/sprites/fighters/sol_tigre".
# Empty = use flat placeholder limbs.
@export var parts_dir: String = ""
# Extra size multiplier on top of the automatic fit. 1.0 = bible spec height.
@export var art_scale: float = 1.0
# Placeholder colors (only used when there is no art).
@export var limb_color: Color = Color(0.85, 0.38, 0.08)
@export var body_color: Color = Color(1.0, 0.45, 0.10)

var _fighter: CharacterBase
var _rig: Node2D                    # everything hangs off this; scaled to fit
var _parts: Dictionary = {}         # name -> Node2D (Sprite2D or Polygon2D)
var _time: float = 0.0
var _has_art: bool = false


func _ready() -> void:
	var parent := get_parent()
	if parent is CharacterBase:
		_fighter = parent

	_rig = Node2D.new()
	_rig.name = "Rig"
	add_child(_rig)

	var textures := _load_textures()
	_has_art = textures.size() == PART_NAMES.size()
	if _has_art:
		_build_sprite_rig(textures)
	else:
		_build_placeholder_rig()


# --- Loading ----------------------------------------------------------------
func _load_textures() -> Dictionary:
	var textures: Dictionary = {}
	if parts_dir.is_empty():
		return textures
	for part_name in PART_NAMES:
		var path := "%s/%s.png" % [parts_dir.rstrip("/"), part_name]
		if ResourceLoader.exists(path):
			textures[part_name] = load(path)
	return textures


# --- Rig construction -------------------------------------------------------
func _build_sprite_rig(textures: Dictionary) -> void:
	var size_of := func(part_name: String) -> Vector2:
		return (textures[part_name] as Texture2D).get_size()

	var torso_height: float = size_of.call("torso").y
	# Work with the hip at the origin; the whole rig gets recentered after.
	var torso_top := -torso_height
	var shoulder_y := torso_top + torso_height * SHOULDER_DROP
	var neck_y := torso_top + torso_height * NECK_DROP

	# Back limbs first so they render behind the body.
	var back_arm := _add_limb_chain(
			_rig, textures, "upper_arm_back", "forearm_back", Vector2(-8.0, shoulder_y))
	var back_leg := _add_limb_chain(
			_rig, textures, "thigh_back", "shin_back", Vector2(-6.0, 0.0))

	# Torso: origin at the hip, image extending upward.
	var torso := _add_sprite(_rig, textures["torso"], Vector2.ZERO, -torso_height * 0.5)
	# Head: origin near the neck stub, image extending upward.
	var head := _add_sprite(
			_rig, textures["head"], Vector2(0.0, neck_y),
			-size_of.call("head").y * (HEAD_PIVOT - 0.5))

	# Front limbs last so they render in front.
	var front_leg := _add_limb_chain(
			_rig, textures, "thigh_front", "shin_front", Vector2(6.0, 0.0))
	var front_arm := _add_limb_chain(
			_rig, textures, "upper_arm_front", "forearm_front", Vector2(9.0, shoulder_y))

	_parts = {
		"torso": torso, "head": head,
		"arm_front": front_arm[0], "elbow_front": front_arm[1],
		"arm_back": back_arm[0], "elbow_back": back_arm[1],
		"leg_front": front_leg[0], "knee_front": front_leg[1],
		"leg_back": back_leg[0], "knee_back": back_leg[1],
	}

	# Top of the head image, and the sole of the front foot, in rig space.
	var knee_y: float = size_of.call("thigh_front").y * (BONE_LENGTH - JOINT_INSET)
	_fit_to_game_scale(
			neck_y - size_of.call("head").y * HEAD_PIVOT,
			knee_y + size_of.call("shin_front").y * (1.0 - JOINT_INSET))


# Adds an upper segment plus a child lower segment hinged at its far end.
# Returns [upper, lower].
func _add_limb_chain(parent: Node2D, textures: Dictionary, upper_name: String,
		lower_name: String, joint: Vector2) -> Array:
	var upper_size: Vector2 = (textures[upper_name] as Texture2D).get_size()
	var upper := _add_sprite(
			parent, textures[upper_name], joint, upper_size.y * (0.5 - JOINT_INSET))
	var elbow_y: float = upper_size.y * (BONE_LENGTH - JOINT_INSET)
	var lower_size: Vector2 = (textures[lower_name] as Texture2D).get_size()
	var lower := _add_sprite(
			upper, textures[lower_name], Vector2(0.0, elbow_y),
			lower_size.y * (0.5 - JOINT_INSET))
	return [upper, lower]


func _add_sprite(parent: Node2D, texture: Texture2D, at: Vector2,
		offset_y: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = at
	sprite.offset = Vector2(0.0, offset_y)
	# The art is high-res and gets scaled DOWN a lot; mipmaps stop it shimmering.
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(sprite)
	return sprite


# Scale and recenter the rig so the assembled fighter matches the bible's
# height spec and stands with its feet on the collision box's bottom edge.
func _fit_to_game_scale(top_y: float, bottom_y: float) -> void:
	var natural_height: float = bottom_y - top_y
	if natural_height <= 0.0:
		return
	var target: float = float(GameConstants.SPRITE_BASE_HEIGHT_PX)
	var fit: float = (target / natural_height) * art_scale
	_rig.scale = Vector2(fit, fit)
	# Center vertically on the fighter's origin (hip currently at rig y = 0).
	_rig.position.y = -((top_y + bottom_y) * 0.5) * fit


# --- Placeholder rig (no art yet) -------------------------------------------
func _build_placeholder_rig() -> void:
	var hip := 30.0
	var shoulder := -32.0
	var back_arm := _add_placeholder_chain(_rig, Vector2(-8.0, shoulder), 10.0, 30.0, 0.25)
	var back_leg := _add_placeholder_chain(_rig, Vector2(-5.0, hip), 12.0, 34.0, 0.25)
	var torso := _add_placeholder(_rig, Vector2(0.0, hip), _taper(14.0, 12.0, shoulder - hip),
			body_color)
	var head := _add_placeholder(_rig, Vector2(0.0, shoulder - 6.0),
			_taper(15.0, 15.0, -32.0), body_color.lightened(0.35))
	var front_leg := _add_placeholder_chain(_rig, Vector2(5.0, hip), 13.0, 35.0, 0.0)
	var front_arm := _add_placeholder_chain(_rig, Vector2(9.0, shoulder), 11.0, 31.0, 0.0)

	_parts = {
		"torso": torso, "head": head,
		"arm_front": front_arm[0], "elbow_front": front_arm[1],
		"arm_back": back_arm[0], "elbow_back": back_arm[1],
		"leg_front": front_leg[0], "knee_front": front_leg[1],
		"leg_back": back_leg[0], "knee_back": back_leg[1],
	}


func _add_placeholder_chain(parent: Node2D, joint: Vector2, half_w: float,
		length: float, darken: float) -> Array:
	var color := limb_color.darkened(darken)
	var upper := _add_placeholder(parent, joint, _taper(half_w, half_w * 0.85, length), color)
	var lower := _add_placeholder(upper, Vector2(0.0, length),
			_taper(half_w * 0.85, half_w * 0.7, length), color)
	return [upper, lower]


func _add_placeholder(parent: Node2D, at: Vector2, points: PackedVector2Array,
		color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = points
	poly.color = color
	poly.position = at
	parent.add_child(poly)
	return poly


func _taper(top_half: float, bottom_half: float, length: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-top_half, 0.0), Vector2(top_half, 0.0),
		Vector2(bottom_half, length), Vector2(-bottom_half, length)])


# --- Per-frame posing -------------------------------------------------------
func _process(delta: float) -> void:
	_time += delta
	if _fighter == null or _parts.is_empty():
		return

	# Mirror the whole puppet to face the opponent.
	scale.x = 1.0 if _fighter.facing >= 0 else -1.0

	match _fighter.state:
		CharacterBase.FightState.KO:
			_pose_ko(delta)
		CharacterBase.FightState.ATTACKING:
			_pose_attack(delta)
		CharacterBase.FightState.BLOCKING:
			_pose_block(delta)
		CharacterBase.FightState.PARRYING:
			_pose_parry(delta)
		CharacterBase.FightState.HITSTUN:
			_pose_hitstun(delta)
		_:
			if absf(_fighter.velocity.x) > 20.0:
				_pose_walk(delta)
			else:
				_pose_idle(delta)


# Each pose is a dictionary of joint -> target angle in degrees.
# 0 deg means the limb hangs straight down; negative swings it forward.
func _apply(pose: Dictionary, delta: float, speed: float = 14.0) -> void:
	for joint in pose:
		var node: Node2D = _parts.get(joint)
		if node != null:
			node.rotation = lerp(
					node.rotation, deg_to_rad(pose[joint]), clampf(delta * speed, 0.0, 1.0))


func _pose_idle(delta: float) -> void:
	_rig.rotation = lerp(_rig.rotation, 0.0, clampf(delta * 12.0, 0.0, 1.0))
	var breathe := sin(_time * 2.6)
	position.y = breathe * 1.5
	_apply({
		"torso": breathe * 1.0, "head": -breathe * 1.0,
		"arm_front": 8.0 + breathe * 3.0, "elbow_front": -18.0,
		"arm_back": -7.0 - breathe * 3.0, "elbow_back": -14.0,
		"leg_front": 2.0, "knee_front": 2.0,
		"leg_back": -2.0, "knee_back": 4.0,
	}, delta)


func _pose_walk(delta: float) -> void:
	_rig.rotation = lerp(_rig.rotation, 0.0, clampf(delta * 12.0, 0.0, 1.0))
	position.y = absf(sin(_time * 9.0)) * -2.5
	var swing := sin(_time * 9.0) * 26.0
	_apply({
		"torso": 3.0, "head": -2.0,
		"arm_front": -swing * 0.55, "elbow_front": -20.0 - maxf(swing, 0.0) * 0.4,
		"arm_back": swing * 0.55, "elbow_back": -20.0 + minf(swing, 0.0) * 0.4,
		"leg_front": swing, "knee_front": maxf(-swing, 0.0) * 0.9,
		"leg_back": -swing, "knee_back": maxf(swing, 0.0) * 0.9,
	}, delta, 18.0)


func _pose_attack(delta: float) -> void:
	position.y = lerp(position.y, 0.0, clampf(delta * 20.0, 0.0, 1.0))
	# The punch follows the real frame data: wind up on startup, full extension
	# exactly on the active frames, pull back through recovery.
	var pose: Dictionary
	match _fighter.get_attack_phase():
		"startup":
			pose = {
				"torso": 6.0, "head": -4.0,
				"arm_front": 40.0, "elbow_front": -95.0,
				"arm_back": -20.0, "elbow_back": -30.0,
				"leg_front": -6.0, "knee_front": 6.0, "leg_back": 8.0, "knee_back": 8.0,
			}
		"active":
			pose = {
				"torso": -9.0, "head": 4.0,
				"arm_front": -92.0, "elbow_front": -4.0,
				"arm_back": 26.0, "elbow_back": -40.0,
				"leg_front": -14.0, "knee_front": 4.0, "leg_back": 14.0, "knee_back": 10.0,
			}
		_:
			pose = {
				"torso": -2.0, "head": 0.0,
				"arm_front": -30.0, "elbow_front": -40.0,
				"arm_back": 8.0, "elbow_back": -24.0,
				"leg_front": -6.0, "knee_front": 4.0, "leg_back": 6.0, "knee_back": 8.0,
			}
	_apply(pose, delta, 26.0)


func _pose_block(delta: float) -> void:
	_apply({
		"torso": -8.0, "head": 6.0,
		"arm_front": -58.0, "elbow_front": -96.0,
		"arm_back": -44.0, "elbow_back": -90.0,
		"leg_front": -6.0, "knee_front": 8.0, "leg_back": 6.0, "knee_back": 10.0,
	}, delta, 22.0)


func _pose_parry(delta: float) -> void:
	_apply({
		"torso": 4.0, "head": -4.0,
		"arm_front": -104.0, "elbow_front": -52.0,
		"arm_back": -50.0, "elbow_back": -70.0,
		"leg_front": -4.0, "knee_front": 4.0, "leg_back": 4.0, "knee_back": 6.0,
	}, delta, 26.0)


func _pose_hitstun(delta: float) -> void:
	_rig.rotation = lerp(_rig.rotation, deg_to_rad(9.0), clampf(delta * 16.0, 0.0, 1.0))
	_apply({
		"torso": 12.0, "head": 14.0,
		"arm_front": 34.0, "elbow_front": -30.0,
		"arm_back": 48.0, "elbow_back": -20.0,
		"leg_front": 10.0, "knee_front": 6.0, "leg_back": -8.0, "knee_back": 14.0,
	}, delta, 18.0)


func _pose_ko(delta: float) -> void:
	# Topple backward onto the floor.
	_rig.rotation = lerp(_rig.rotation, deg_to_rad(-80.0), clampf(delta * 7.0, 0.0, 1.0))
	_apply({
		"torso": 6.0, "head": 18.0,
		"arm_front": 30.0, "elbow_front": -14.0,
		"arm_back": -28.0, "elbow_back": -10.0,
		"leg_front": -16.0, "knee_front": 22.0, "leg_back": 12.0, "knee_back": 16.0,
	}, delta, 8.0)
