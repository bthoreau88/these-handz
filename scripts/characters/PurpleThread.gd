# =============================================================================
# PurpleThread.gd — G1-07 PURPLE THREAD. Whip Zoner.
# Kit: Yarn Lash (long thin poke), Knot Trap (snare), Thread Spin (whirl),
# Unravel (her super — uses the universal super slot for now).
# Tuning in GameConstants.PURPLE_THREAD (Project Rule 1).
# =============================================================================
class_name PurpleThread
extends CharacterBase

const TRAP_SCENE := preload("res://scenes/projectiles/KnotTrap.tscn")


func _init() -> void:
	display_name = "PURPLE THREAD"
	tuning = GameConstants.PURPLE_THREAD


# Special A: Yarn Lash — the longest normal poke in the game.
func special_a() -> void:
	start_attack("yarn_lash")


# Special B: Knot Trap — a snare on the floor; light damage, long freeze.
func special_b() -> void:
	if not cooldown_ready("trap", tuning["trap_cooldown_seconds"]):
		return
	start_cast(GameConstants.SPECIAL_CAST_RECOVERY_FRAMES)
	var trap: KnotTrap = TRAP_SCENE.instantiate()
	get_parent().add_child(trap)
	trap.global_position = global_position + Vector2(facing * 170.0, 55.0)
	trap.launch(self, facing)


# Charge (hold): Thread Spin — whip whirl centered on her body.
func charge_attack() -> void:
	start_attack("thread_spin")
