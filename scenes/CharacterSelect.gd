# =============================================================================
# CharacterSelect.gd — touch-first select screen (Project Rule 3: buttons are
# finger-sized). Tap once to pick Player 1, again for Player 2, then FIGHT.
# The buttons are generated from Roster.FIGHTERS so the locked roster stays
# defined in exactly one place.
# =============================================================================
extends Control

var _picking: int = 1   # 1 = choosing P1, 2 = choosing P2, 3 = ready

@onready var status_label: Label = $Layout/Status
@onready var grid: GridContainer = $Layout/Grid
@onready var fight_button: Button = $Layout/Buttons/FightButton


func _ready() -> void:
	for id in Roster.FIGHTERS:
		var button := Button.new()
		button.text = Roster.display_name(id)
		button.custom_minimum_size = Vector2(250, 100)
		button.pressed.connect(_on_fighter_pressed.bind(id))
		grid.add_child(button)
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


func _on_fight_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/FightScene.tscn")


func _on_reset_pressed() -> void:
	_reset_picks()


func _reset_picks() -> void:
	_picking = 1
	_refresh()


func _refresh() -> void:
	fight_button.disabled = _picking != 3
	match _picking:
		1:
			status_label.text = "TAP A FIGHTER FOR PLAYER 1"
		2:
			status_label.text = "P1: %s — NOW TAP PLAYER 2" % Roster.display_name(Roster.pick_p1)
		3:
			status_label.text = "%s  VS  %s" % [
				Roster.display_name(Roster.pick_p1), Roster.display_name(Roster.pick_p2)]
