# =============================================================================
# KnotTrap.gd — Purple Thread's snare. Same trap mechanics as Dot Trap but
# tuned for a long freeze instead of damage
# (GameConstants.PROJECTILES["knot_trap"]).
# =============================================================================
class_name KnotTrap
extends ProjectileBase


func launch(from: CharacterBase, dir: int) -> void:
	var data: Dictionary = GameConstants.PROJECTILES["knot_trap"]
	configure(from, dir, data, data["damage"])
