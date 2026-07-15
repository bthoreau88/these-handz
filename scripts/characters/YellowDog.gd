# =============================================================================
# YellowDog.gd — G1-08 YELLOW DOG. Wild Card object fighter. The mascot.
# Kit: Brick Toss, Smoke Cloud, Deadpan Charge.
# Tuning lives in GameConstants.YELLOW_DOG (Project Rule 1).
#
# !!! BALANCE: brick damage is flagged OVERPOWERED in the bible (§04). The
# number lives in GameConstants.YELLOW_DOG["brick_damage"] — tune it there.
# =============================================================================
class_name YellowDog
extends CharacterBase

const BRICK_SCENE := preload("res://scenes/projectiles/BrickProjectile.tscn")


func _init() -> void:
	display_name = "YELLOW DOG"
	tuning = GameConstants.YELLOW_DOG


# Special A: Brick Toss — arcs under gravity.
func special_a() -> void:
	if not cooldown_ready("brick", tuning["brick_cooldown_seconds"]):
		return
	start_cast(GameConstants.SPECIAL_CAST_RECOVERY_FRAMES)

	var brick: BrickProjectile = BRICK_SCENE.instantiate()
	get_parent().add_child(brick)
	brick.global_position = global_position + Vector2(facing * 50.0, -60.0)
	brick.launch(self, facing)


# Special B: Smoke Cloud — a gray cloud drops where Yellow Dog stands and
# he fades to 35% visibility for the duration.
func special_b() -> void:
	if not cooldown_ready("smoke", tuning["smoke_cloud_cooldown_seconds"]):
		return
	start_cast(GameConstants.SPECIAL_CAST_RECOVERY_FRAMES)
	_run_smoke_cloud()


func _run_smoke_cloud() -> void:
	var duration: float = tuning["smoke_cloud_duration_seconds"]

	var cloud := ColorRect.new()
	cloud.color = Color(0.6, 0.6, 0.65, 0.55)
	cloud.size = Vector2(220.0, 220.0)
	cloud.add_to_group("projectiles") # so round resets clear it too
	get_parent().add_child(cloud)
	cloud.global_position = global_position - cloud.size * 0.5

	modulate.a = 0.35
	await get_tree().create_timer(duration).timeout
	modulate.a = 1.0
	if is_instance_valid(cloud):
		cloud.queue_free()


# Deadpan Charge uses the universal hold-to-charge entry point.
func charge_attack() -> void:
	# TODO(roadmap: after hitboxes): armor during charge walk.
	start_attack("heavy")
