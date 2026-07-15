# =============================================================================
# SolTigre.gd — G1-01 SOL TIGRE. Rushdown + Tiger Companion. Miami, FL.
# Fighting style: Tigre Flujo. Fast walk speed, slightly reduced damage
# (tuning in GameConstants.SOL_TIGRE — Project Rule 1).
# =============================================================================
class_name SolTigre
extends CharacterBase

const TIGER_SCENE := preload("res://scenes/projectiles/TigerCompanion.tscn")


func _init() -> void:
	display_name = "SOL TIGRE"
	tuning = GameConstants.SOL_TIGRE


# Special A: the tiger dashes across the stage from behind Sol Tigre.
func special_a() -> void:
	if not cooldown_ready("tiger", tuning["tiger_cooldown_seconds"]):
		return
	start_cast(GameConstants.SPECIAL_CAST_RECOVERY_FRAMES)

	var tiger: TigerCompanion = TIGER_SCENE.instantiate()
	get_parent().add_child(tiger)
	tiger.global_position = global_position + Vector2(-facing * 90.0, 20.0)
	tiger.launch(self, facing)


# Special B: Tigre Flujo rush — placeholder as a fast medium until real
# frame data exists.
func special_b() -> void:
	start_attack("medium")
