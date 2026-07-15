# =============================================================================
# BrickProjectile.gd — Yellow Dog's Brick Toss. Arcs under gravity.
# Damage comes from GameConstants.YELLOW_DOG["brick_damage"], which is
# FLAGGED OVERPOWERED in the bible — tune it there, nowhere else.
# =============================================================================
class_name BrickProjectile
extends ProjectileBase


func launch(from: CharacterBase, dir: int) -> void:
	configure(from, dir, GameConstants.PROJECTILES["brick"],
			GameConstants.YELLOW_DOG["brick_damage"])
