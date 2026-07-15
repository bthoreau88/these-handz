# =============================================================================
# Roster.gd — the LOCKED Game 1 roster (bible §03). Do not add, remove, or
# rename fighters here without a bible change.
#
# Godot note (static var): `static` members belong to the class itself, not
# to an instance, so CharacterSelect can write the picks and FightScene can
# read them after the scene change without any node surviving in between.
# =============================================================================
class_name Roster
extends RefCounted

# Insertion order = display order on the select screen (roster numbers 01-08).
const FIGHTERS: Dictionary = {
	"sol_tigre":     {"name": "SOL TIGRE",     "scene": "res://scenes/fighters/SolTigre.tscn"},
	"crown_saint":   {"name": "CROWN SAINT",   "scene": "res://scenes/fighters/CrownSaint.tscn"},
	"the_architect": {"name": "THE ARCHITECT", "scene": "res://scenes/fighters/TheArchitect.tscn"},
	"dotty":         {"name": "DOTTY",         "scene": "res://scenes/fighters/Dotty.tscn"},
	"fresh":         {"name": "FRESH",         "scene": "res://scenes/fighters/Fresh.tscn"},
	"cyborg_stitch": {"name": "CYBORG STITCH", "scene": "res://scenes/fighters/CyborgStitch.tscn"},
	"purple_thread": {"name": "PURPLE THREAD", "scene": "res://scenes/fighters/PurpleThread.tscn"},
	"yellow_dog":    {"name": "YELLOW DOG",    "scene": "res://scenes/fighters/YellowDog.tscn"},
}

# Defaults let FightScene.tscn run standalone (F6) without the select screen.
static var pick_p1: String = "sol_tigre"
static var pick_p2: String = "yellow_dog"

# Player 2 can be a CPU so one person can play solo (e.g. on a phone).
# ai_difficulty is a key into GameConstants.AI_DIFFICULTY.
static var p2_is_cpu: bool = true
static var ai_difficulty: String = "NORMAL"


static func display_name(id: String) -> String:
	return FIGHTERS[id]["name"]


static func load_fighter_scene(id: String) -> PackedScene:
	return load(FIGHTERS[id]["scene"])
