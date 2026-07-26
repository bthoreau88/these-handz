# =============================================================================
# FighterVisual.gd — a placeholder ANIMATION PUPPET for one fighter.
#
# This is the vertical-slice proof of the "puppet-rigged HD anime" pipeline
# (see ART_DIRECTION.md). It builds a crude jointed figure out of Polygon2D
# limbs at runtime and poses those limbs every frame based on the fighter's
# FightState — so the fighter bobs when idle, strides when walking, winds up
# and throws a punch on attacks, guards when blocking, and topples on KO.
#
# WHY THIS MATTERS: nothing here is the real art. It's the RIG. When you draw
# Sol Tigre's body parts in Krita and export them as PNGs, you swap each
# Polygon2D for a Sprite2D of the matching part and keep this exact posing
# code — the joints, timing, and state hookup are already done. The gray
# rectangle is gone; a moving skeleton stands in its place, waiting for skin.
#
# Godot notes:
#  - Polygon2D is a Node2D, so it has position/rotation; rotating it spins its
#    shape about its own origin. We place each limb's origin AT its joint
#    (shoulder, hip) and draw the limb hanging down from there, so rotating the
#    node swings the limb naturally.
#  - Children draw in order, so back limbs are added first (behind the torso)
#    and front limbs last (in front) — cheap depth.
#  - We read the parent through the public CharacterBase API only (Rule 2 in
#    spirit): state, facing, velocity, get_attack_phase(). No private pokes.
# =============================================================================
class_name FighterVisual
extends Node2D

# Joint anchor points in local space (origin = fighter center; +y is down,
# body is ~180 tall so top ≈ -90, feet ≈ +90).
const HIP_Y := 30.0
const SHOULDER_Y := -32.0

# Body palette — overridable per fighter later. Defaults to Sol Tigre orange.
@export var limb_color: Color = Color(0.85, 0.38, 0.08)
@export var body_color: Color = Color(1.0, 0.45, 0.10)
@export var head_color: Color = Color(1.0, 0.72, 0.45)

var _fighter: CharacterBase
var _front_arm: Polygon2D
var _back_arm: Polygon2D
var _front_leg: Polygon2D
var _back_leg: Polygon2D
var _torso: Polygon2D
var _head: Polygon2D
var _time: float = 0.0


func _ready() -> void:
	var parent := get_parent()
	if parent is CharacterBase:
		_fighter = parent

	# Back limbs first (drawn behind the torso), then torso/head, then front.
	_back_arm = _make_limb(Vector2(-8.0, SHOULDER_Y), _rect(10.0, 48.0), limb_color.darkened(0.25))
	_back_leg = _make_limb(Vector2(-5.0, HIP_Y), _rect(12.0, 60.0), limb_color.darkened(0.25))
	_torso = _make_limb(Vector2(0.0, HIP_Y), _torso_points(), body_color)
	_head = _make_limb(Vector2(0.0, SHOULDER_Y - 6.0), _head_points(), head_color)
	_front_leg = _make_limb(Vector2(5.0, HIP_Y), _rect(13.0, 62.0), limb_color)
	_front_arm = _make_limb(Vector2(9.0, SHOULDER_Y), _rect(11.0, 50.0), limb_color)


func _process(delta: float) -> void:
	_time += delta
	if _fighter == null:
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


# --- Poses ------------------------------------------------------------------
func _pose_idle(delta: float) -> void:
	rotation = _approach(rotation, 0.0, delta, 12.0)
	position.y = sin(_time * 3.0) * 2.0
	var sway := sin(_time * 3.0) * 4.0
	_set(_front_arm, 6.0 + sway, delta)
	_set(_back_arm, -6.0 - sway, delta)
	_set(_front_leg, 0.0, delta)
	_set(_back_leg, 0.0, delta)
	_set(_torso, 0.0, delta)


func _pose_walk(delta: float) -> void:
	rotation = _approach(rotation, 0.0, delta, 12.0)
	position.y = absf(sin(_time * 10.0)) * -3.0
	var swing := sin(_time * 10.0) * 28.0
	_set(_front_leg, swing, delta, 20.0)
	_set(_back_leg, -swing, delta, 20.0)
	_set(_front_arm, -swing * 0.6, delta, 20.0)
	_set(_back_arm, swing * 0.6, delta, 20.0)
	_set(_torso, 4.0, delta)


func _pose_attack(delta: float) -> void:
	position.y = _approach(position.y, 0.0, delta, 20.0)
	# The punch arc follows the real frame data: wind back on startup, thrust
	# on the active frames, recover home. -90 deg points the arm forward.
	var target := 6.0
	match _fighter.get_attack_phase():
		"startup":
			target = 45.0     # cock the fist back
		"active":
			target = -98.0    # full extension toward the opponent
		"recovery":
			target = -30.0    # pulling back in
	_set(_front_arm, target, delta, 26.0)
	_set(_back_arm, 10.0, delta)
	_set(_torso, -6.0, delta)
	_set(_front_leg, -8.0, delta)
	_set(_back_leg, 6.0, delta)


func _pose_block(delta: float) -> void:
	_set(_front_arm, -75.0, delta, 22.0)
	_set(_back_arm, -60.0, delta, 22.0)
	_set(_torso, -8.0, delta)
	_set(_front_leg, -6.0, delta)
	_set(_back_leg, 4.0, delta)


func _pose_parry(delta: float) -> void:
	_set(_front_arm, -115.0, delta, 26.0)
	_set(_back_arm, -70.0, delta, 26.0)
	_set(_torso, 4.0, delta)


func _pose_hitstun(delta: float) -> void:
	rotation = _approach(rotation, deg_to_rad(10.0), delta, 16.0)
	_set(_front_arm, 40.0, delta, 18.0)
	_set(_back_arm, 55.0, delta, 18.0)
	_set(_torso, 10.0, delta)


func _pose_ko(delta: float) -> void:
	# Topple backward onto the floor.
	rotation = _approach(rotation, deg_to_rad(-82.0), delta, 8.0)
	_set(_front_arm, 30.0, delta, 8.0)
	_set(_back_arm, -30.0, delta, 8.0)


# --- Helpers ----------------------------------------------------------------
# Lerp a limb's rotation (in degrees) toward a target, framerate-independent.
func _set(limb: Polygon2D, target_deg: float, delta: float, speed: float = 14.0) -> void:
	limb.rotation = _approach(limb.rotation, deg_to_rad(target_deg), delta, speed)


func _approach(current: float, target: float, delta: float, speed: float) -> float:
	return lerp(current, target, clampf(delta * speed, 0.0, 1.0))


func _make_limb(joint: Vector2, points: PackedVector2Array, color: Color) -> Polygon2D:
	var limb := Polygon2D.new()
	limb.polygon = points
	limb.color = color
	limb.position = joint
	add_child(limb)
	return limb


# A limb rectangle of the given half-width, hanging DOWN from the joint (0,0).
func _rect(half_w: float, length: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-half_w, 0.0), Vector2(half_w, 0.0),
		Vector2(half_w * 0.8, length), Vector2(-half_w * 0.8, length)])


# Torso tapers UP from the hip to the shoulders.
func _torso_points() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-14.0, 0.0), Vector2(14.0, 0.0),
		Vector2(12.0, SHOULDER_Y - HIP_Y), Vector2(-12.0, SHOULDER_Y - HIP_Y)])


# Head box sits above the shoulders.
func _head_points() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-15.0, -10.0), Vector2(15.0, -10.0),
		Vector2(15.0, -42.0), Vector2(-15.0, -42.0)])
