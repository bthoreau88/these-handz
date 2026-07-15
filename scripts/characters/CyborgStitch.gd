# =============================================================================
# CyborgStitch.gd — G1-06 CYBORG STITCH. Power Striker.
# Kit: Circuit Slam (huge overhead), Chain Break (chain projectile),
# Stitch Surge. Tuning in GameConstants.CYBORG_STITCH (Project Rule 1).
# =============================================================================
class_name CyborgStitch
extends CharacterBase

const CHAIN_SCENE := preload("res://scenes/projectiles/ChainProjectile.tscn")


func _init() -> void:
	display_name = "CYBORG STITCH"
	tuning = GameConstants.CYBORG_STITCH


# Special A: Chain Break — fast horizontal chain shot.
func special_a() -> void:
	if not cooldown_ready("chain", tuning["chain_cooldown_seconds"]):
		return
	start_cast(GameConstants.SPECIAL_CAST_RECOVERY_FRAMES)
	var chain: ChainProjectile = CHAIN_SCENE.instantiate()
	get_parent().add_child(chain)
	chain.global_position = global_position + Vector2(facing * 60.0, 0.0)
	chain.launch(self, facing)


# Special B: Circuit Slam — slow, massive overhead.
func special_b() -> void:
	start_attack("circuit_slam")


# Charge (hold): Stitch Surge — gray-box as an empowered heavy for now.
# TODO(roadmap: Phase 5 polish): real surge behavior from bible §04.
func charge_attack() -> void:
	start_attack("heavy")
