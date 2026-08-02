# =============================================================================
# FightScene.gd — glue for the gray-box fight scene (ROADMAP steps 1-4).
# Wires: fighters <-> InputRouter, fighters -> UI bars, RoundManager -> UI.
# No gameplay numbers live here (Project Rule 1) and no input is read here
# (Project Rule 2) — this script only connects existing pieces.
#
# Godot note (@onready): these variables are filled with scene nodes right
# before _ready() runs, so we can grab children by their node paths.
# =============================================================================
extends Node2D

var player1: CharacterBase
var player2: CharacterBase

@onready var input_router: InputRouter = $InputRouter
@onready var round_manager: RoundManager = $RoundManager
@onready var stage_background: StageBackground = $StageBackground
@onready var fight_camera: FightCamera = $FightCamera

@onready var health_bar_p1: ProgressBar = $UI/HealthP1
@onready var health_bar_p2: ProgressBar = $UI/HealthP2
@onready var meter_bar_p1: ProgressBar = $UI/MeterP1
@onready var meter_bar_p2: ProgressBar = $UI/MeterP2
@onready var name_label_p1: Label = $UI/NameP1
@onready var name_label_p2: Label = $UI/NameP2
@onready var timer_label: Label = $UI/TimerLabel
@onready var announce_label: Label = $UI/AnnounceLabel


func _ready() -> void:
	# Backdrop first, so it is behind everything the fight adds.
	stage_background.setup(Roster.stage_id())

	# Fighters come from the select screen via Roster's static picks
	# (defaults to Sol Tigre vs Yellow Dog when this scene runs standalone).
	player1 = _spawn_fighter(Roster.pick_p1, 1, $SpawnP1.position)
	player2 = _spawn_fighter(Roster.pick_p2, 2, $SpawnP2.position)

	# Fighters need to know each other for range checks and face-off.
	player1.opponent = player2
	player2.opponent = player1
	player1.facing = 1
	player2.facing = -1

	# Solo play: hand Player 2 to the CPU brain (chosen on the select screen).
	if Roster.p2_is_cpu:
		var brain := AIController.new()
		brain.name = "AIController"
		player2.add_child(brain)
		brain.setup(player2, Roster.ai_difficulty)

	name_label_p1.text = player1.display_name
	name_label_p2.text = player2.display_name
	if Roster.p2_is_cpu:
		name_label_p2.text += " (CPU)"

	# Health / meter bars (children finished _ready() first, so .meter exists).
	player1.health_changed.connect(_on_health_changed.bind(health_bar_p1))
	player2.health_changed.connect(_on_health_changed.bind(health_bar_p2))
	player1.meter.meter_changed.connect(_on_meter_changed.bind(meter_bar_p1))
	player2.meter.meter_changed.connect(_on_meter_changed.bind(meter_bar_p2))

	player1.desperation_activated.connect(_on_desperation)
	player2.desperation_activated.connect(_on_desperation)
	player1.parry_succeeded.connect(_on_parry)
	player2.parry_succeeded.connect(_on_parry)

	# The camera frames both fighters — and its motion is what makes the
	# parallax layers move, so the stage only reads as deep once this runs.
	fight_camera.setup(player1, player2)

	input_router.setup(player1, player2, Roster.p2_is_cpu)

	round_manager.setup(player1, player2, input_router)
	round_manager.countdown_tick.connect(_on_countdown_tick)
	round_manager.round_started.connect(_on_round_started)
	round_manager.round_ended.connect(_on_round_ended)
	round_manager.match_ended.connect(_on_match_ended)
	round_manager.time_left_changed.connect(_on_time_left_changed)
	round_manager.start_match()


func _spawn_fighter(id: String, pid: int, spawn: Vector2) -> CharacterBase:
	var fighter: CharacterBase = Roster.load_fighter_scene(id).instantiate()
	fighter.player_id = pid
	# Position BEFORE add_child: the fighter records its spawn point for
	# round resets inside its own _ready().
	fighter.position = spawn
	add_child(fighter)
	return fighter


func _on_health_changed(current: float, max_value: float, bar: ProgressBar) -> void:
	bar.max_value = max_value
	bar.value = current


func _on_meter_changed(value: float, bar: ProgressBar) -> void:
	bar.value = value


func _on_countdown_tick(text: String) -> void:
	announce_label.text = text
	if text == "FIGHT!":
		# Let "FIGHT!" linger for a beat, then clear it.
		await get_tree().create_timer(0.7).timeout
		if announce_label.text == "FIGHT!":
			announce_label.text = ""


func _on_round_started(round_number: int) -> void:
	announce_label.text = "ROUND %d" % round_number


func _on_round_ended(winner_id: int, _wins: Dictionary) -> void:
	if winner_id == 0:
		announce_label.text = "DRAW — RERUN ROUND"
	else:
		announce_label.text = "%s TAKES THE ROUND" % _fighter_name(winner_id)


func _on_match_ended(winner_id: int) -> void:
	announce_label.text = "%s WINS!" % _fighter_name(winner_id)
	await get_tree().create_timer(GameConstants.MATCH_END_RETURN_DELAY).timeout
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")


func _on_time_left_changed(seconds: int) -> void:
	timer_label.text = str(seconds)


func _on_desperation(player_id: int) -> void:
	announce_label.text = "%s — DESPERATION!" % _fighter_name(player_id)


func _on_parry(player_id: int) -> void:
	announce_label.text = "%s PARRY!" % _fighter_name(player_id)


func _fighter_name(player_id: int) -> String:
	return player1.display_name if player_id == 1 else player2.display_name
