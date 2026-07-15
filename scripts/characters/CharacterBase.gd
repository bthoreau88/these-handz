# =============================================================================
# CharacterBase.gd — every fighter extends this.
# Owns: health, the FightState machine, hitbox/hurtbox hit detection with
# real frame timing (startup -> active -> recovery), movement + pushback,
# HANDZ meter and parry integration, and Desperation Mode.
#
# Project Rule 2: characters NEVER read input directly. The only way input
# reaches a fighter is receive_gesture(), called by InputRouter. There is no
# Input.is_action_pressed() anywhere in this file or any fighter script.
#
# Godot note (Area2D hit detection): each fighter carries two Area2D children,
# built in code in _create_combat_areas():
#   - Hurtbox: always on, body-sized, sits on collision layer 2. "Where I can
#     be hit."
#   - Hitbox: normally off. During an attack's ACTIVE frames it is switched on
#     in front of the fighter with that attack's size (from
#     GameConstants.ATTACKS), and it scans layer 2 for the opponent's hurtbox.
# Whiffing at max range now genuinely misses, and hits can only land during
# active frames. Set GameConstants.DEBUG_SHOW_HITBOXES to see both boxes.
#
# Fighting games think in frames, not seconds — at 60 fps, 6 frames = 0.1 s.
# `_state_frames` counts down in _physics_process; when it hits 0 the state
# resolves (attack advances a phase, parry whiffs, stun ends).
# =============================================================================
class_name CharacterBase
extends CharacterBody2D

signal health_changed(current: float, max_value: float)
signal defeated(player_id: int)
signal desperation_activated(player_id: int)
signal parry_succeeded(player_id: int)

enum FightState { IDLE, ATTACKING, BLOCKING, PARRYING, HITSTUN, KO }

@export var player_id: int = 1

var display_name: String = "FIGHTER"
# Per-character tuning dictionary from GameConstants; fighters set this.
var tuning: Dictionary = {}

var health: float
var state: FightState = FightState.IDLE
var meter: HandzMeter
var parry: ParrySystem
var opponent: CharacterBase
var facing: int = 1                 # 1 = faces right, -1 = faces left
var desperation: bool = false
var spawn_position: Vector2
var hurtbox: Area2D                 # opponent's hitbox looks for this

var _hitbox: Area2D
var _hitbox_shape: RectangleShape2D
var _debug_draw: Node2D
var _state_frames: int = 0          # frames left in the current state
var _attack_name: String = ""       # attack in progress, "" if none
var _attack_phase: String = ""      # "startup", "active" or "recovery"
var _attack_hit_done: bool = false  # each attack lands at most once
var _block_held: bool = false       # keyboard D held down
var _walk_input: int = 0            # -1 / 0 / 1 from walk gestures
var _pushback: float = 0.0          # decaying knockback velocity (px/s)
var _dash_frames: int = 0
var _cooldowns: Dictionary = {}     # special name -> ready-again msec


func _ready() -> void:
	health = GameConstants.MAX_HEALTH
	spawn_position = global_position

	meter = HandzMeter.new()
	meter.name = "HandzMeter"
	add_child(meter)

	parry = ParrySystem.new()
	parry.name = "ParrySystem"
	add_child(parry)
	parry.parry_whiffed.connect(_on_parry_whiffed)

	_create_combat_areas()

	health_changed.emit(health, GameConstants.MAX_HEALTH)


func _create_combat_areas() -> void:
	hurtbox = Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 2   # "I can be hit" layer
	hurtbox.collision_mask = 0    # the hurtbox itself looks for nothing
	var hurt_shape := CollisionShape2D.new()
	var hurt_rect := RectangleShape2D.new()
	hurt_rect.size = GameConstants.HURTBOX_SIZE
	hurt_shape.shape = hurt_rect
	hurtbox.add_child(hurt_shape)
	add_child(hurtbox)

	_hitbox = Area2D.new()
	_hitbox.name = "Hitbox"
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 2    # scans for hurtboxes
	_hitbox.monitoring = false    # off except during active frames
	_hitbox.monitorable = false
	var hit_shape := CollisionShape2D.new()
	_hitbox_shape = RectangleShape2D.new()
	hit_shape.shape = _hitbox_shape
	_hitbox.add_child(hit_shape)
	add_child(_hitbox)

	# Debug overlay: a child drawn on top of both fighters (z_index 10).
	# We connect to its `draw` signal instead of subclassing it.
	_debug_draw = Node2D.new()
	_debug_draw.name = "DebugDraw"
	_debug_draw.z_index = 10
	add_child(_debug_draw)
	_debug_draw.draw.connect(_on_debug_draw)


func _physics_process(delta: float) -> void:
	# Gravity + floor collision keep the gray-box rectangles standing.
	if not is_on_floor():
		velocity.y += GameConstants.GRAVITY * delta
	velocity.x = _compute_x_velocity(delta)
	move_and_slide()
	_clamp_to_stage()

	if GameConstants.DEBUG_SHOW_HITBOXES:
		_debug_draw.queue_redraw()

	if state == FightState.KO:
		return

	# Always turn toward the opponent while free to act.
	if state == FightState.IDLE and opponent != null:
		facing = 1 if opponent.global_position.x > global_position.x else -1

	parry.tick()
	_tick_active_hit()
	_tick_state()


func _compute_x_velocity(delta: float) -> float:
	var x := 0.0
	if _dash_frames > 0:
		_dash_frames -= 1
		x = facing * GameConstants.DASH_SPEED
	elif state == FightState.IDLE:
		x = _walk_input * tuning.get("walk_speed", GameConstants.WALK_SPEED)
	# Pushback stacks on top and bleeds off over a few frames.
	_pushback = move_toward(_pushback, 0.0, GameConstants.PUSHBACK_DECAY * delta)
	return x + _pushback


func _clamp_to_stage() -> void:
	var stage_width := get_viewport_rect().size.x
	global_position.x = clampf(
			global_position.x,
			GameConstants.STAGE_EDGE_MARGIN,
			stage_width - GameConstants.STAGE_EDGE_MARGIN)


# --- Input entry point (called by InputRouter ONLY) -------------------------
func receive_gesture(gesture: Dictionary) -> void:
	# Key/finger releases must always register, even mid-stun, or a fighter
	# could get stuck blocking or walking forever.
	if gesture["type"] == "action" and String(gesture["action"]).ends_with("_end"):
		_handle_release(gesture["action"])
		return

	if not can_act():
		return

	match gesture["type"]:
		"tap":
			start_attack("light")
		"swipe":
			_handle_swipe(gesture["dir"])
		"action":
			_handle_action(gesture["action"])


func can_act() -> bool:
	return state == FightState.IDLE


func _handle_swipe(dir: String) -> void:
	var forward := "right" if facing == 1 else "left"
	if dir == forward:
		# Bible §05: forward swipe is medium OR dash. Out of reach = dash in,
		# in reach = medium attack (threshold in GameConstants).
		if opponent != null and _distance_to_opponent() > GameConstants.DASH_TRIGGER_DISTANCE:
			_start_dash()
		else:
			start_attack("medium")
	elif dir == "up":
		start_attack("jump_attack")
	elif dir == "down":
		start_attack("low")
	# Swipe away from the opponent: TODO(roadmap: movement pass): backdash.


func _handle_action(action: String) -> void:
	match action:
		"light", "medium", "heavy":
			start_attack(action)
		"super":
			try_super()
		"special_a":
			special_a()
		"special_b":
			special_b()
		"block_start":
			_block_held = true
			_start_block(0)      # 0 = held, ends on block_end
		"block_tap":
			_start_block(GameConstants.BLOCK_TAP_DURATION_FRAMES)
		"parry":
			_start_parry()
		"charge":
			charge_attack()
		"walk_left_start":
			_walk_input = -1
		"walk_right_start":
			_walk_input = 1


func _handle_release(action: String) -> void:
	match action:
		"block_end":
			_end_block()
		"walk_left_end":
			if _walk_input == -1:
				_walk_input = 0
		"walk_right_end":
			if _walk_input == 1:
				_walk_input = 0


# --- Movement ----------------------------------------------------------------
func _distance_to_opponent() -> float:
	return absf(opponent.global_position.x - global_position.x)


func _start_dash() -> void:
	_dash_frames = GameConstants.DASH_DURATION_FRAMES


# --- Attacks ----------------------------------------------------------------
func start_attack(attack_name: String) -> void:
	if not GameConstants.ATTACKS.has(attack_name):
		push_warning("Unknown attack: " + attack_name)
		return
	state = FightState.ATTACKING
	_attack_name = attack_name
	_attack_phase = "startup"
	_attack_hit_done = false
	_state_frames = GameConstants.ATTACKS[attack_name]["startup"]
	# Jump attack actually leaves the ground.
	if attack_name == "jump_attack" and is_on_floor():
		velocity.y = GameConstants.JUMP_VELOCITY


# Shared cooldown gate for specials. Returns true AND starts the cooldown
# if the special named `key` is ready; returns false while still cooling.
func cooldown_ready(key: String, seconds: float) -> bool:
	var now := Time.get_ticks_msec()
	if now < int(_cooldowns.get(key, 0)):
		return false
	_cooldowns[key] = now + int(seconds * 1000.0)
	return true


# Specials that spawn something (brick, tiger) still need commitment: this
# locks the fighter in a recovery-only "cast" for a few frames, using the
# ATTACKING state with no hitbox.
func start_cast(frames: int) -> void:
	state = FightState.ATTACKING
	_attack_name = ""
	_attack_phase = "recovery"
	_state_frames = frames


func try_super() -> void:
	# Desperation Mode discount: super at 50% meter (bible §05).
	var cost: float = GameConstants.DESPERATION_SUPER_COST if desperation \
			else GameConstants.METER_COST_SUPER
	if meter.try_spend(cost):
		start_attack("super")


# Startup just ended: switch the hitbox on in front of us (or centered on
# us for radial bursts like Crown Sign / Thread Spin).
func _begin_active_frames() -> void:
	var data: Dictionary = GameConstants.ATTACKS[_attack_name]
	_hitbox_shape.size = data["hitbox_size"]
	var offset_x := 0.0
	if not data.get("centered", false):
		offset_x = facing * (GameConstants.HURTBOX_SIZE.x * 0.5 + data["hitbox_size"].x * 0.5)
	_hitbox.position = Vector2(offset_x, data["hitbox_y"])
	_hitbox.monitoring = true
	_attack_phase = "active"
	_state_frames = data["active"]


# Runs every physics frame; lands the hit if the hitbox overlaps the
# opponent's hurtbox during active frames.
func _tick_active_hit() -> void:
	if state != FightState.ATTACKING or _attack_phase != "active":
		return
	if _attack_hit_done or opponent == null:
		return
	for area in _hitbox.get_overlapping_areas():
		if area == opponent.hurtbox:
			_attack_hit_done = true
			var data: Dictionary = GameConstants.ATTACKS[_attack_name]
			var damage: float = data["damage"] * tuning.get("damage_multiplier", 1.0)
			if desperation:
				damage *= 1.0 + GameConstants.DESPERATION_DAMAGE_BONUS
			var landed: bool = opponent.take_hit(
					damage, self, data["hitstun"], data.get("unblockable", false))
			if landed:
				meter.on_hit_landed()
			return


func _end_active_frames() -> void:
	_hitbox.monitoring = false
	_attack_phase = "recovery"
	_state_frames = GameConstants.ATTACKS[_attack_name]["recovery"]


func _end_attack() -> void:
	_hitbox.monitoring = false
	_attack_name = ""
	_attack_phase = ""


# Returns true if the hit really connected (false if parried or blocked).
# unblockable hits (grabs) go through block, but a parry still beats them.
func take_hit(damage: float, attacker: CharacterBase, hitstun: int,
		unblockable: bool = false) -> bool:
	if state == FightState.KO:
		return false

	var push_dir := 1.0 if global_position.x >= attacker.global_position.x else -1.0

	# Parry check first: an open window beats everything (bible §05).
	if state == FightState.PARRYING and parry.is_active():
		parry.succeed()
		meter.on_parry_success()
		# Melee: the parried attacker eats the advantage stun. Projectiles:
		# the hit is negated but the (distant, idle) owner is not stunned.
		if attacker.state == FightState.ATTACKING:
			attacker.apply_parry_stun()
		state = FightState.IDLE
		parry_succeeded.emit(player_id)
		return false

	if state == FightState.BLOCKING and not unblockable:
		_apply_damage(damage * GameConstants.BLOCK_CHIP_MULTIPLIER)
		_pushback = push_dir * GameConstants.PUSHBACK_BLOCK_SPEED
		# Blocking holds; just add a touch of blockstun by extending the state.
		if _state_frames > 0:
			_state_frames += GameConstants.BLOCKSTUN_FRAMES
		return false

	_apply_damage(damage)
	meter.on_hit_taken()
	_pushback = push_dir * GameConstants.PUSHBACK_HIT_SPEED
	if state != FightState.KO:
		if state == FightState.ATTACKING:
			_end_attack()   # getting hit cancels your own attack
		state = FightState.HITSTUN
		_state_frames = hitstun
	return true


func _apply_damage(damage: float) -> void:
	health = maxf(health - damage, 0.0)
	health_changed.emit(health, GameConstants.MAX_HEALTH)

	if not desperation and health <= GameConstants.MAX_HEALTH * GameConstants.DESPERATION_HP_THRESHOLD:
		desperation = true
		desperation_activated.emit(player_id)

	if health <= 0.0:
		_end_attack()
		state = FightState.KO
		defeated.emit(player_id)


# The defender's "12-frame advantage": the parried attacker is locked out.
func apply_parry_stun() -> void:
	_end_attack()
	state = FightState.HITSTUN
	_state_frames = GameConstants.PARRY_SUCCESS_ADVANTAGE_FRAMES


# --- Block & parry ----------------------------------------------------------
func _start_block(frames: int) -> void:
	state = FightState.BLOCKING
	_state_frames = frames


func _end_block() -> void:
	_block_held = false
	if state == FightState.BLOCKING:
		state = FightState.IDLE
		_state_frames = 0


func _start_parry() -> void:
	state = FightState.PARRYING
	parry.begin()
	_state_frames = 0 # ParrySystem owns this timer; see _on_parry_whiffed.


func _on_parry_whiffed() -> void:
	if state != FightState.PARRYING:
		return
	# Whiffed parry = punishable recovery + 2% consolation meter (bible §05).
	meter.on_parry_fail()
	state = FightState.HITSTUN
	_state_frames = GameConstants.PARRY_WHIFF_RECOVERY_FRAMES


# --- Per-frame state resolution ---------------------------------------------
func _tick_state() -> void:
	if _state_frames <= 0:
		return
	_state_frames -= 1
	if _state_frames > 0:
		return

	match state:
		FightState.ATTACKING:
			match _attack_phase:
				"startup":
					_begin_active_frames()
				"active":
					_end_active_frames()
				"recovery":
					_end_attack()
					state = FightState.IDLE
		FightState.HITSTUN:
			state = FightState.IDLE
		FightState.BLOCKING:
			if not _block_held:
				state = FightState.IDLE
		_:
			pass


# --- Debug overlay (GameConstants.DEBUG_SHOW_HITBOXES) -----------------------
func _on_debug_draw() -> void:
	if not GameConstants.DEBUG_SHOW_HITBOXES:
		return
	var half: Vector2 = GameConstants.HURTBOX_SIZE * 0.5
	_debug_draw.draw_rect(
			Rect2(-half, GameConstants.HURTBOX_SIZE), Color(0.2, 1.0, 0.3, 0.5), false, 2.0)
	if state == FightState.ATTACKING and _attack_phase == "active":
		var size: Vector2 = _hitbox_shape.size
		_debug_draw.draw_rect(
				Rect2(_hitbox.position - size * 0.5, size), Color(1.0, 0.15, 0.15, 0.4), true)


# --- Specials & charge: fighters override these ------------------------------
func special_a() -> void:
	pass


func special_b() -> void:
	pass


func charge_attack() -> void:
	# TODO(roadmap: after hitboxes): hold-to-charge heavy.
	pass


# --- Round lifecycle (called by RoundManager) --------------------------------
func reset_for_round() -> void:
	health = GameConstants.MAX_HEALTH
	desperation = false
	state = FightState.IDLE
	_state_frames = 0
	_end_attack()
	_block_held = false
	_walk_input = 0
	_pushback = 0.0
	_dash_frames = 0
	parry.cancel()
	modulate.a = 1.0   # undo smoke-cloud style fades
	global_position = spawn_position
	velocity = Vector2.ZERO
	meter.carry_over()
	health_changed.emit(health, GameConstants.MAX_HEALTH)
