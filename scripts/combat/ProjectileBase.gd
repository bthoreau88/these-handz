# =============================================================================
# ProjectileBase.gd — shared base for everything a fighter spawns that can
# hit: Yellow Dog's brick, Sol Tigre's tiger companion, Cyborg Stitch's chain
# (later). Numbers live in GameConstants.PROJECTILES (Project Rule 1).
#
# Usage from a fighter script (order matters — add to the tree FIRST):
#     var p := SOME_SCENE.instantiate()
#     get_parent().add_child(p)
#     p.global_position = ...
#     p.launch(self, facing)
#
# Hit detection mirrors CharacterBase: we POLL get_overlapping_areas() each
# physics frame instead of using area_entered signals, so take_hit() is free
# to flip hitbox monitoring without "flushing queries" errors.
#
# Every projectile joins the "projectiles" group; RoundManager clears the
# group between rounds.
# =============================================================================
class_name ProjectileBase
extends Area2D

var source: CharacterBase
var damage: float = 0.0
var hitstun: int = 12
var move_velocity: Vector2 = Vector2.ZERO
var gravity_scale: float = 0.0
var _life_left: float = 3.0
var _arm_left: float = 0.0    # traps: seconds until the hit area goes live
var _hit_shape: RectangleShape2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2      # scans for hurtboxes, like an attack hitbox
	monitorable = false
	add_to_group("projectiles")
	var shape_node := CollisionShape2D.new()
	_hit_shape = RectangleShape2D.new()
	shape_node.shape = _hit_shape
	add_child(shape_node)


# Subclasses call this from their launch() with their PROJECTILES entry.
func configure(from: CharacterBase, dir: int, data: Dictionary, damage_override: float) -> void:
	source = from
	damage = damage_override
	hitstun = data["hitstun"]
	move_velocity = Vector2(dir * data["speed_x"], data["speed_y"])
	gravity_scale = data["gravity_scale"]
	_life_left = data["lifetime"]
	_arm_left = data.get("arm_delay", 0.0)
	_hit_shape.size = data["size"]


func _physics_process(delta: float) -> void:
	move_velocity.y += GameConstants.GRAVITY * gravity_scale * delta
	global_position += move_velocity * delta

	_life_left -= delta
	if _life_left <= 0.0 or _is_off_stage():
		queue_free()
		return

	if _arm_left > 0.0:
		_arm_left -= delta
		return
	_check_hit()


func _check_hit() -> void:
	if source == null or source.opponent == null:
		return
	for area in get_overlapping_areas():
		if area == source.opponent.hurtbox:
			var landed: bool = source.opponent.take_hit(damage, source, hitstun)
			if landed:
				source.meter.on_hit_landed()
			queue_free()
			return


func _is_off_stage() -> bool:
	var stage_width := get_viewport_rect().size.x
	return global_position.x < -100.0 or global_position.x > stage_width + 100.0 \
			or global_position.y > 900.0
