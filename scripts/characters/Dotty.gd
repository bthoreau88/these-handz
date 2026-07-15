# =============================================================================
# Dotty.gd — G1-04 DOTTY. Setplay Trickster.
# Kit: Dot Trap mines, Runway Rush (attack out of a dash), Scarf Snare
# (long freeze to set up more traps). Tuning in GameConstants.DOTTY.
# =============================================================================
class_name Dotty
extends CharacterBase

const TRAP_SCENE := preload("res://scenes/projectiles/DotTrap.tscn")


func _init() -> void:
	display_name = "DOTTY"
	tuning = GameConstants.DOTTY


# Special A: Dot Trap — drops a mine ahead of her that arms after a beat.
func special_a() -> void:
	if not cooldown_ready("trap", tuning["trap_cooldown_seconds"]):
		return
	start_cast(GameConstants.SPECIAL_CAST_RECOVERY_FRAMES)
	var trap: DotTrap = TRAP_SCENE.instantiate()
	get_parent().add_child(trap)
	trap.global_position = global_position + Vector2(facing * 170.0, 55.0)
	trap.launch(self, facing)


# Special B: Runway Rush — dash and strike in one motion.
func special_b() -> void:
	_start_dash()
	start_attack("runway_rush")


# Charge (hold): Scarf Snare — little damage, long freeze.
func charge_attack() -> void:
	start_attack("scarf_snare")
