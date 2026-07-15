# =============================================================================
# CharacterSelect.gd — touch-first select screen (Project Rule 3: buttons are
# finger-sized). Tap once to pick Player 1, again for Player 2, then FIGHT.
# The buttons are generated from Roster.FIGHTERS so the locked roster stays
# defined in exactly one place.
#
# The MODE button cycles Player 2 between a CPU (three difficulties) and a
# second human, so one person can demo the game solo — including on a phone.
# =============================================================================
extends Control

# Order the MODE button cycles through. CPU entries name a difficulty key
# from GameConstants.AI_DIFFICULTY; "HUMAN" means a second player.
const P2_MODES: Array[String] = ["NORMAL", "EASY", "DUMMY", "HUMAN"]

var _picking: int = 1   # 1 = choosing P1, 2 = choosing P2, 3 = ready
var _mode_index: int = 0

@onready var status_label: Label = $Layout/Status
@onready var grid: GridContainer = $Layout/Grid
@onready var fight_button: Button = $Layout/Buttons/FightButton
@onready var mode_button: Button = $Layout/Buttons/ModeButton


func _ready() -> void:
	for id in Roster.FIGHTERS:
		var button := Button.new()
		button.text = Roster.display_name(id)
		button.custom_minimum_size = Vector2(250, 100)
		button.pressed.connect(_on_fighter_pressed.bind(id))
		grid.add_child(button)
	_apply_mode()
	_reset_picks()


func _on_fighter_pressed(id: String) -> void:
	match _picking:
		1:
			Roster.pick_p1 = id
			_picking = 2
		2:
			Roster.pick_p2 = id
			_picking = 3
	_refresh()


func _on_mode_pressed() -> void:
	_mode_index = (_mode_index + 1) % P2_MODES.size()
	_apply_mode()
	_refresh()


func _apply_mode() -> void:
	var mode := P2_MODES[_mode_index]
	Roster.p2_is_cpu = mode != "HUMAN"
	if Roster.p2_is_cpu:
		Roster.ai_difficulty = mode
		mode_button.text = "P2: CPU (%s)" % mode
	else:
		mode_button.text = "P2: HUMAN"


func _on_fight_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/FightScene.tscn")


func _on_reset_pressed() -> void:
	_reset_picks()


func _reset_picks() -> void:
	_picking = 1
	_refresh()


func _refresh() -> void:
	fight_button.disabled = _picking != 3
	var p2_label := "CPU" if Roster.p2_is_cpu else "PLAYER 2"
	match _picking:
		1:
			status_label.text = "TAP A FIGHTER FOR PLAYER 1"
		2:
			status_label.text = "P1: %s — NOW TAP %s'S FIGHTER" % [
				Roster.display_name(Roster.pick_p1), p2_label]
		3:
			status_label.text = "%s  VS  %s%s" % [
				Roster.display_name(Roster.pick_p1),
				Roster.display_name(Roster.pick_p2),
				"  (CPU)" if Roster.p2_is_cpu else ""]
