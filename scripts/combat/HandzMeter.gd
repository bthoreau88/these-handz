# =============================================================================
# HandzMeter.gd — the HANDZ super meter (bible §05).
# One instance lives inside each CharacterBase (created in its _ready()).
# Runs 0-100. Thresholds: 25% EX moves, 50% BREAK, 100% Super.
# 50% of meter carries over between rounds. In Desperation Mode the super
# costs DESPERATION_SUPER_COST instead of the full bar.
# All numbers come from GameConstants (Project Rule 1).
# =============================================================================
class_name HandzMeter
extends Node

signal meter_changed(value: float)

var value: float = 0.0


func add(amount: float) -> void:
	value = clampf(value + amount, 0.0, GameConstants.METER_MAX)
	meter_changed.emit(value)


func on_hit_landed() -> void:
	add(GameConstants.METER_GAIN_HIT_LANDED)


func on_hit_taken() -> void:
	add(GameConstants.METER_GAIN_HIT_TAKEN)


func on_parry_success() -> void:
	add(GameConstants.METER_GAIN_PARRY_SUCCESS)


func on_parry_fail() -> void:
	add(GameConstants.METER_GAIN_PARRY_FAIL)


func can_afford(cost: float) -> bool:
	return value >= cost


# Returns true and subtracts the cost if there is enough meter.
func try_spend(cost: float) -> bool:
	if not can_afford(cost):
		return false
	value -= cost
	meter_changed.emit(value)
	return true


func has_ex() -> bool:
	return can_afford(GameConstants.METER_COST_EX)


func has_break() -> bool:
	return can_afford(GameConstants.METER_COST_BREAK)


func has_super() -> bool:
	return can_afford(GameConstants.METER_COST_SUPER)


# Called between rounds: keep 50% (bible §05 round carry rule).
func carry_over() -> void:
	value *= GameConstants.METER_ROUND_CARRY
	meter_changed.emit(value)
