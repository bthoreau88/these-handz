# =============================================================================
# TheArchitect.gd — G1-03 THE ARCHITECT. Zoner, Soul Cipher.
# Kit: Cipher Orb (slow projectile), Coat Catch (projectile negate — full
# reflect is a TODO), Phase Step (short teleport).
# Tuning in GameConstants.THE_ARCHITECT (Project Rule 1).
# =============================================================================
class_name TheArchitect
extends CharacterBase

const ORB_SCENE := preload("res://scenes/projectiles/CipherOrb.tscn")

var _coat_frames: int = 0


func _init() -> void:
	display_name = "THE ARCHITECT"
	tuning = GameConstants.THE_ARCHITECT


func _physics_process(delta: float) -> void:
	super(delta)
	if _coat_frames > 0:
		_coat_frames -= 1


# Special A: Cipher Orb — slow zoning projectile.
func special_a() -> void:
	if not cooldown_ready("orb", tuning["orb_cooldown_seconds"]):
		return
	start_cast(GameConstants.SPECIAL_CAST_RECOVERY_FRAMES)
	var orb: CipherOrb = ORB_SCENE.instantiate()
	get_parent().add_child(orb)
	orb.global_position = global_position + Vector2(facing * 60.0, -10.0)
	orb.launch(self, facing)


# Special B: Phase Step — blink forward (through the opponent if close).
func special_b() -> void:
	if not cooldown_ready("phase_step", tuning["phase_step_cooldown_seconds"]):
		return
	start_cast(GameConstants.SPECIAL_CAST_RECOVERY_FRAMES)
	global_position.x += facing * tuning["phase_step_distance"]
	# _clamp_to_stage() keeps this on screen next physics frame.


# Charge (hold): Coat Catch — for a short window incoming PROJECTILES are
# swallowed by the coat. Rewarded like a parry.
func charge_attack() -> void:
	if not cooldown_ready("coat", tuning["coat_cooldown_seconds"]):
		return
	_coat_frames = tuning["coat_window_frames"]


func take_hit(damage: float, attacker: CharacterBase, hitstun: int,
		unblockable: bool = false) -> bool:
	# A projectile's owner is not mid-swing; melee attackers are ATTACKING.
	# TODO(roadmap: Phase 5 polish): actually reflect the projectile back
	# instead of just eating it.
	if _coat_frames > 0 and attacker.state != FightState.ATTACKING:
		_coat_frames = 0
		meter.add(GameConstants.METER_GAIN_PARRY_SUCCESS)
		return false
	return super.take_hit(damage, attacker, hitstun, unblockable)
