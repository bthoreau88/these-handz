# =============================================================================
# AIController.gd — a CPU brain for one fighter, so a solo player can demo the
# game on a single device (or phone). FightScene adds one of these as a child
# of Player 2 when the select screen chose "CPU".
#
# Project Rule 2 (characters never read input): this controller does NOT reach
# into the fighter's guts. It builds the SAME gesture dictionaries GestureInput
# emits and calls fighter.receive_gesture(...) — exactly the path a human's
# taps take through InputRouter. The fighter cannot tell it apart from a person,
# so this works for all 8 fighters with zero per-character code.
#
# All numbers come from GameConstants.AI_DIFFICULTY (Project Rule 1). It thinks
# on a slow timer (not every frame) so it stays reflexy-but-beatable.
#
# Godot note (randf): randf() returns a random float 0.0-1.0; we compare it to
# the tuned probabilities to make each decision a coin-flip with loaded odds.
# =============================================================================
class_name AIController
extends Node

var fighter: CharacterBase
var _cfg: Dictionary
var _think_left: float = 0.0
var _walking_dir: int = 0   # -1 left, 0 none, 1 right — mirrors held-walk input


# FightScene calls this right after adding the controller to the fighter.
func setup(controlled: CharacterBase, difficulty: String) -> void:
	fighter = controlled
	_cfg = GameConstants.AI_DIFFICULTY.get(
			difficulty, GameConstants.AI_DIFFICULTY[GameConstants.AI_DEFAULT_DIFFICULTY])
	_think_left = _cfg["think_interval"]


func _physics_process(delta: float) -> void:
	if fighter == null or fighter.opponent == null:
		return

	# React to an incoming attack every frame (defense can't wait for the
	# think timer or it would be too slow to ever block).
	_maybe_defend()

	_think_left -= delta
	if _think_left > 0.0:
		return
	_think_left = _cfg["think_interval"]
	_decide()


# --- Fast defensive reflex --------------------------------------------------
func _maybe_defend() -> void:
	if not fighter.can_act():
		return
	var opp: CharacterBase = fighter.opponent
	# Only worry when the opponent is mid-attack and close enough to connect.
	if opp.state != CharacterBase.FightState.ATTACKING:
		return
	if _distance() > _cfg["attack_range"]:
		return
	var roll := randf()
	if roll < _cfg["parry_chance"]:
		_send_action("parry")
	elif roll < _cfg["block_chance"]:
		_start_block()


# --- Slow decision tick -----------------------------------------------------
func _decide() -> void:
	if not fighter.can_act():
		return

	# Drop any block we were holding before doing something else.
	_stop_block_if_held()

	var dist := _distance()

	# Super when it's charged and the tuned threshold is met.
	if fighter.meter.value >= _cfg["super_at_meter"] and dist <= _cfg["attack_range"]:
		_send_action("super")
		return

	if dist > _cfg["approach_range"]:
		_approach()
		return

	if dist <= _cfg["attack_range"]:
		_stop_walk()
		if randf() < _cfg["aggression"]:
			_attack()
		return

	# Mid-range: close the gap.
	_approach()


func _approach() -> void:
	var dir := 1 if fighter.opponent.global_position.x > fighter.global_position.x else -1
	# Occasionally dash in with a forward swipe instead of plain walking.
	if randf() < 0.3:
		_stop_walk()
		_send_swipe("right" if dir == 1 else "left")
	else:
		_set_walk(dir)


func _attack() -> void:
	if randf() < _cfg["special_chance"]:
		_send_action("special_a" if randf() < 0.5 else "special_b")
		return
	# Weighted normal: mostly light/medium, sometimes heavy.
	var roll := randf()
	if roll < 0.45:
		_send_tap()          # light
	elif roll < 0.8:
		_send_swipe("right" if fighter.facing == 1 else "left")  # forward = medium
	else:
		_send_action("heavy")


# --- Walk state (held input needs a start and a matching end) ---------------
func _set_walk(dir: int) -> void:
	if _walking_dir == dir:
		return
	_stop_walk()
	_walking_dir = dir
	_send_action("walk_right_start" if dir == 1 else "walk_left_start")


func _stop_walk() -> void:
	if _walking_dir == 1:
		_send_action("walk_right_end")
	elif _walking_dir == -1:
		_send_action("walk_left_end")
	_walking_dir = 0


# --- Block state ------------------------------------------------------------
func _start_block() -> void:
	_send_action("block_start")


func _stop_block_if_held() -> void:
	# Harmless if we weren't blocking; the fighter ignores a stray block_end.
	_send_action("block_end")


# --- Gesture builders (mirror GestureInput's output shape) ------------------
func _distance() -> float:
	return absf(fighter.opponent.global_position.x - fighter.global_position.x)


func _send_tap() -> void:
	fighter.receive_gesture({"device": "cpu", "position": Vector2.ZERO, "type": "tap"})


func _send_swipe(dir: String) -> void:
	fighter.receive_gesture({
		"device": "cpu", "position": Vector2.ZERO, "type": "swipe", "dir": dir})


func _send_action(action: String) -> void:
	fighter.receive_gesture({
		"device": "cpu", "position": Vector2.ZERO, "type": "action", "action": action})
