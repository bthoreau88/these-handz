# =============================================================================
# CrownSaint.gd — G1-02 CROWN SAINT. Brawler with Faith Power.
# Signature: Crown Sign bursts — a radial blast centered on his own body.
# Tuning in GameConstants.CROWN_SAINT (Project Rule 1).
# =============================================================================
class_name CrownSaint
extends CharacterBase


func _init() -> void:
	display_name = "CROWN SAINT"
	tuning = GameConstants.CROWN_SAINT


# Special A: Crown Sign burst — hits all around him (centered hitbox).
func special_a() -> void:
	if not cooldown_ready("burst", tuning["burst_cooldown_seconds"]):
		return
	start_attack("crown_burst")


# Special B: faith-driven advancing strike — gray-box as a heavy for now.
# TODO(roadmap: Phase 5 polish): real frame data from bible §04.
func special_b() -> void:
	start_attack("heavy")
