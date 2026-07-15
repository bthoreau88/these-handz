# =============================================================================
# Fresh.gd — G1-05 FRESH. Pure Grappler — NO projectiles, ever (bible §04).
# Kit: command grab (ignores block), Bucket Counter auto-reversal.
# Tuning in GameConstants.FRESH (Project Rule 1).
# =============================================================================
class_name Fresh
extends CharacterBase

var _counter_frames: int = 0


func _init() -> void:
	display_name = "FRESH"
	tuning = GameConstants.FRESH


func _physics_process(delta: float) -> void:
	super(delta)
	if _counter_frames > 0:
		_counter_frames -= 1


# Special A: command grab — short reach, huge damage, goes through block.
func special_a() -> void:
	start_attack("fresh_grab")


# Special B: Bucket Counter — for a short window, any MELEE hit that
# connects is auto-reversed: negated and punished.
func special_b() -> void:
	if not cooldown_ready("counter", tuning["counter_cooldown_seconds"]):
		return
	_counter_frames = tuning["counter_window_frames"]


func take_hit(damage: float, attacker: CharacterBase, hitstun: int,
		unblockable: bool = false) -> bool:
	if _counter_frames > 0 and attacker.state == FightState.ATTACKING:
		_counter_frames = 0
		# The reversal: their hit becomes ours.
		attacker.take_hit(
				tuning["counter_damage"] * tuning.get("damage_multiplier", 1.0),
				self,
				tuning["counter_stun_frames"])
		meter.on_hit_landed()
		return false
	return super.take_hit(damage, attacker, hitstun, unblockable)
