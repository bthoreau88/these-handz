# =============================================================================
# ParrySystem.gd — the 6-frame parry (bible §05).
# One instance lives inside each CharacterBase (created in its _ready()).
#
# Flow:
#   - CharacterBase calls begin() when a parry gesture arrives.
#   - The window stays open PARRY_WINDOW_FRAMES physics frames.
#   - If an attack lands while open, CharacterBase calls succeed():
#       +15% meter for the defender, attacker eats a
#       PARRY_SUCCESS_ADVANTAGE_FRAMES stun (the "12-frame advantage").
#   - If the window closes with nothing parried, whiffed() fires:
#       +2% consolation meter and the character enters a punishable
#       recovery state (handled by CharacterBase).
#
# tick() must be called once per physics frame by the owning character.
# =============================================================================
class_name ParrySystem
extends Node

signal parry_succeeded
signal parry_whiffed

var _frames_left: int = 0


func begin() -> void:
	_frames_left = GameConstants.PARRY_WINDOW_FRAMES


func is_active() -> bool:
	return _frames_left > 0


# Called every physics frame by CharacterBase while a parry is pending.
func tick() -> void:
	if _frames_left <= 0:
		return
	_frames_left -= 1
	if _frames_left == 0:
		parry_whiffed.emit()


# Called by CharacterBase when an incoming attack meets an open window.
func succeed() -> void:
	_frames_left = 0
	parry_succeeded.emit()


func cancel() -> void:
	_frames_left = 0
