# =============================================================================
# InputRouter.gd — decides WHICH fighter a gesture belongs to (Project Rule 2:
# GestureInput -> InputRouter -> CharacterBase.receive_gesture()).
#
# Touch: left half of the screen controls Player 1, right half Player 2.
# Keyboard: always Player 1 (desktop testing fallback).
#
# Solo vs CPU: when Player 2 is a CPU (an AIController drives it), the human
# owns the WHOLE screen — every human gesture goes to Player 1, so one person
# can play with the full window / keyboard on a phone.
#
# Desktop tip: project.godot enables "emulate_touch_from_mouse", so clicking /
# dragging the mouse on the right half of the window drives Player 2 (in a
# two-human match).
# =============================================================================
class_name InputRouter
extends Node

var _player1: CharacterBase
var _player2: CharacterBase
var _routing_enabled: bool = true
var _single_player: bool = false


func setup(player1: CharacterBase, player2: CharacterBase, single_player: bool = false) -> void:
	_player1 = player1
	_player2 = player2
	_single_player = single_player
	if not GestureInput.gesture_detected.is_connected(_on_gesture_detected):
		GestureInput.gesture_detected.connect(_on_gesture_detected)


# RoundManager turns routing off during countdowns and after KO.
func set_routing_enabled(enabled: bool) -> void:
	_routing_enabled = enabled


func _on_gesture_detected(gesture: Dictionary) -> void:
	if not _routing_enabled or _player1 == null or _player2 == null:
		return

	var target: CharacterBase
	if _single_player or gesture["device"] == "keyboard":
		# Solo match (or keyboard): the human is always Player 1.
		target = _player1
	else:
		var half_x: float = get_viewport().get_visible_rect().size.x * 0.5
		target = _player1 if gesture["position"].x < half_x else _player2

	target.receive_gesture(gesture)
