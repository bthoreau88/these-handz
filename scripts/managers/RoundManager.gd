# =============================================================================
# RoundManager.gd — best-of-3 match flow (bible §05).
# Owns: the pre-round countdown, the 60-second round timer, win tracking,
# round resets (with 50% meter carry via CharacterBase.reset_for_round()).
#
# The scene (FightScene.gd) calls setup() then start_match(), and listens to
# the signals below to drive UI text. This node never touches UI directly.
#
# Godot note (await): `await get_tree().create_timer(1.0).timeout` pauses THIS
# function for 1 second without freezing the game — that's how the countdown
# and between-round delays work.
# =============================================================================
class_name RoundManager
extends Node

signal countdown_tick(text: String)          # "3", "2", "1", "FIGHT!"
signal round_started(round_number: int)
signal round_ended(winner_id: int, wins: Dictionary)  # winner_id 0 = draw
signal match_ended(winner_id: int)
signal time_left_changed(seconds: int)

var _player1: CharacterBase
var _player2: CharacterBase
var _router: InputRouter
var _wins: Dictionary = {1: 0, 2: 0}
var _round_number: int = 0
var _time_left: float = 0.0
var _fighting: bool = false


func setup(player1: CharacterBase, player2: CharacterBase, router: InputRouter) -> void:
	_player1 = player1
	_player2 = player2
	_router = router
	_player1.defeated.connect(_on_player_defeated)
	_player2.defeated.connect(_on_player_defeated)


func start_match() -> void:
	_wins = {1: 0, 2: 0}
	_round_number = 0
	_start_round()


func _start_round() -> void:
	_round_number += 1
	# Bricks, tigers and smoke from the last round don't carry over.
	for projectile in get_tree().get_nodes_in_group("projectiles"):
		projectile.queue_free()
	_player1.reset_for_round()
	_player2.reset_for_round()
	_time_left = GameConstants.ROUND_TIME_SECONDS
	time_left_changed.emit(int(_time_left))
	_router.set_routing_enabled(false)
	round_started.emit(_round_number)
	await get_tree().create_timer(1.0).timeout

	for i in range(GameConstants.PRE_ROUND_COUNTDOWN, 0, -1):
		countdown_tick.emit(str(i))
		await get_tree().create_timer(1.0).timeout
	countdown_tick.emit("FIGHT!")

	_router.set_routing_enabled(true)
	_fighting = true


func _process(delta: float) -> void:
	if not _fighting:
		return
	var previous_second := int(_time_left)
	_time_left = maxf(_time_left - delta, 0.0)
	if int(_time_left) != previous_second:
		time_left_changed.emit(int(_time_left))
	if _time_left <= 0.0:
		_on_time_up()


func _on_player_defeated(loser_id: int) -> void:
	if not _fighting:
		return
	_end_round(2 if loser_id == 1 else 1)


func _on_time_up() -> void:
	# Time-out: whoever has more health takes the round; a tie is a draw
	# round that no one scores, and it is replayed.
	var winner_id := 0
	if _player1.health > _player2.health:
		winner_id = 1
	elif _player2.health > _player1.health:
		winner_id = 2
	_end_round(winner_id)


func _end_round(winner_id: int) -> void:
	_fighting = false
	_router.set_routing_enabled(false)
	if winner_id != 0:
		_wins[winner_id] += 1
	round_ended.emit(winner_id, _wins)

	if winner_id != 0 and _wins[winner_id] >= GameConstants.ROUNDS_TO_WIN:
		await get_tree().create_timer(GameConstants.BETWEEN_ROUNDS_DELAY).timeout
		match_ended.emit(winner_id)
	else:
		await get_tree().create_timer(GameConstants.BETWEEN_ROUNDS_DELAY).timeout
		_start_round()
