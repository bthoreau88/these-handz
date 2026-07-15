# =============================================================================
# CipherOrb.gd — The Architect's slow zoning orb (Soul Cipher).
# Numbers in GameConstants.PROJECTILES["cipher_orb"].
# =============================================================================
class_name CipherOrb
extends ProjectileBase


func launch(from: CharacterBase, dir: int) -> void:
	var data: Dictionary = GameConstants.PROJECTILES["cipher_orb"]
	configure(from, dir, data, data["damage"])
