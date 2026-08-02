# =============================================================================
# FightCamera.gd — the standard 2D-fighter camera.
#
# Sits on the midpoint between the two fighters and pulls back as they
# separate, so both stay framed without either leaving the screen. Its motion
# is also what drives the parallax layers: ParallaxBackground reads the active
# camera, so a still camera means a dead backdrop.
#
# All feel values live in GameConstants (CAMERA_*) — Project Rule 1.
# =============================================================================
class_name FightCamera
extends Camera2D

var _p1: CharacterBase
var _p2: CharacterBase


func setup(player1: CharacterBase, player2: CharacterBase) -> void:
	_p1 = player1
	_p2 = player2
	make_current()
	# Snap to the opening framing instead of gliding in from the corner.
	global_position = _target_position()
	zoom = Vector2.ONE * _target_zoom()


func _physics_process(delta: float) -> void:
	if _p1 == null or _p2 == null:
		return
	var weight: float = clampf(delta * GameConstants.CAMERA_SMOOTH_SPEED, 0.0, 1.0)
	global_position = global_position.lerp(_target_position(), weight)
	var target_zoom: float = _target_zoom()
	zoom = zoom.lerp(Vector2.ONE * target_zoom, weight)


func _target_position() -> Vector2:
	var midpoint: float = (_p1.global_position.x + _p2.global_position.x) * 0.5
	# Keep the view inside the stage. The visible half-width grows as we zoom
	# out, so the clamp has to account for the current zoom.
	var half_view: float = (get_viewport_rect().size.x * 0.5) / maxf(_target_zoom(), 0.01)
	var min_x: float = half_view
	var max_x: float = GameConstants.STAGE_PLAY_WIDTH - half_view
	if min_x > max_x:
		# Stage narrower than the view: just centre it.
		midpoint = GameConstants.STAGE_PLAY_WIDTH * 0.5
	else:
		midpoint = clampf(midpoint, min_x, max_x)
	return Vector2(
			midpoint,
			GameConstants.STAGE_GROUND_Y * 0.5 - GameConstants.CAMERA_VERTICAL_OFFSET)


func _target_zoom() -> float:
	var separation: float = absf(_p2.global_position.x - _p1.global_position.x)
	var t: float = clampf(separation / GameConstants.CAMERA_ZOOM_DISTANCE, 0.0, 1.0)
	return lerpf(GameConstants.CAMERA_ZOOM_IN, GameConstants.CAMERA_ZOOM_OUT, t)
