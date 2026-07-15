# =============================================================================
# DotTrap.gd — Dotty's mine. Sits still, arms after a beat (arm_delay in
# GameConstants.PROJECTILES["dot_trap"]), pops whoever steps on it.
# =============================================================================
class_name DotTrap
extends ProjectileBase


func launch(from: CharacterBase, dir: int) -> void:
	var data: Dictionary = GameConstants.PROJECTILES["dot_trap"]
	configure(from, dir, data, data["damage"])
