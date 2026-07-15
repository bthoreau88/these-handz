# =============================================================================
# InputRouter.gd — decides WHICH fighter a gesture belongs to (Project Rule 2:
# GestureInput -> InputRouter -> CharacterBase.receive_gesture()).
#
# Touch: left half of the screen controls Player 1, right half Player 2.
# Keyboard: always Player 1 (desktop testing fallback).
#
# Desktop tip: project.godot enables "emulate_touch_from_mouse", so clicking /
# dragging the mouse on the right half of the window drives Player 2.
# =============================================================================
class_name InputRouter
extends Node

var _player1: CharacterBase
var _player2: CharacterBase
var _routing_enabled: bool = true


func setup(player1: CharacterBase, player2: CharacterBase) -> void:
	_player1 = player1
	_player2 = player2
	if not GestureInput.gesture_detected.is_connected(_on_gesture_detected):
		GestureInput.gesture_detected.connect(_on_gesture_detected)


# RoundManager turns routing off during countdowns and after KO.
func set_routing_enabled(enabled: bool) -> void:
	_routing_enabled = enabled


func _on_gesture_detected(gesture: Dictionary) -> void:
	if not _routing_enabled or _player1 == null or _player2 == null:
		return

	var target: CharacterBase
	if gesture["device"] == "keyboard":
		target = _player1
	else:
		var half_x: float = get_viewport().get_visible_rect().size.x * 0.5
		target = _player1 if gesture["position"].x < half_x else _player2

	target.receive_gesture(gesture)
