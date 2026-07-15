# =============================================================================
# ChainProjectile.gd — groundwork for Cyborg Stitch's Chain Break (G1-06).
# Flies straight and fast. NO FIGHTER FIRES THIS YET — it exists so the
# shared projectile base is proven against a third shape before Phase 5
# builds the rest of the cast.
# =============================================================================
class_name ChainProjectile
extends ProjectileBase


func launch(from: CharacterBase, dir: int) -> void:
	var data: Dictionary = GameConstants.PROJECTILES["chain"]
	configure(from, dir, data, data["damage"])
