# =============================================================================
# TigerCompanion.gd — Sol Tigre's assist. Dashes flat across the stage,
# hits once, then is gone. Cooldown lives in SolTigre.gd; damage and speed
# in GameConstants (SOL_TIGRE["tiger_damage"], PROJECTILES["tiger"]).
# =============================================================================
class_name TigerCompanion
extends ProjectileBase


func launch(from: CharacterBase, dir: int) -> void:
	configure(from, dir, GameConstants.PROJECTILES["tiger"],
			GameConstants.SOL_TIGRE["tiger_damage"])
