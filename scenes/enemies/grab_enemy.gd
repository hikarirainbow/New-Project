class_name GrabEnemy
extends Actor

@export_group("Enemy Settings")
@export var patrol_speed: float = 60.0
@export var chase_speed: float = 90.0
@export var contact_damage: int = 15
@export var chase_radius: float = 100.0
@export var sp_gain: int = 1

@export_group("AI Parameters")
@export var wall_raycast_length: float = 24.0
@export var wall_jump_force: float = 250.0
@export var jump_height_threshold: float = -10.0
@export var contact_hitbox_size: Vector2 = Vector2(50.0, 70.0)

@export_group("Drops")
@export var key_name_to_drop: String = "Boss Key"
@export var key_pickup_radius: float = 20.0

enum State { PATROL, CHASE, DEAD, ATTRACTED }
var current_state: State = State.PATROL

var direction: int = 1
var player_ref: Player = null
var contact_area: Area2D = null
var is_being_raped: bool = false

# Attack Settings
@export_group("Attack Settings")
@export var attack_range: float = 60.0
@export var attack_cooldown: float = 2.2
@export var attack_duration: float = 1.0
@export var attack_damage_window_start: float = 0.8
@export var attack_damage_window_end: float = 0.95

var attack_cooldown_timer: float = 0.0
var attack_active_timer: float = 0.0
var is_attacking_state: bool = false
var has_dealt_damage_this_attack: bool = false

@onready var edge_right: RayCast2D = $RayCast2D_EdgeRight
@onready var edge_left: RayCast2D = $RayCast2D_EdgeLeft
@onready var wall_ray: RayCast2D = $RayCast2D_Wall

# Cấu hình ngưỡng ánh sáng hiển thị trực tiếp qua Inspector (0.0 = nhạy nhất, 1.0 = tắt)
@export_group("Shadow Shroud")
@export_range(0.0, 1.0) var shadow_shroud_light_threshold: float = 0.05:
	set(val):
		shadow_shroud_light_threshold = val
		if is_inside_tree():
			_update_shadow_shroud_material()

func _ready() -> void:
	add_to_group("enemies")
	
	if current_state == State.DEAD:
		collision_layer = 0
		collision_mask = 1
		if has_node("Sprite2D"):
			$Sprite2D.modulate = Color(0.5, 0.5, 0.5, 1.0)
		return
		
	_setup_contact_area()
	
	# Cache player reference once
	await get_tree().process_frame
	player_ref = get_tree().get_first_node_in_group("player") as Player

func set_as_corpse() -> void:
	current_state = State.DEAD

func _update_shadow_shroud_material() -> void:
	if has_node("Sprite2D") and $Sprite2D.material is ShaderMaterial:
		$Sprite2D.material.set_shader_parameter("light_threshold", shadow_shroud_light_threshold)

func _setup_contact_area() -> void:
	contact_area = Area2D.new()
	contact_area.name = "ContactDamageArea"
	contact_area.collision_layer = 0
	contact_area.collision_mask = 2 # Detect Player (Layer 2)
	
	var col_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = contact_hitbox_size
	col_shape.shape = rect
	contact_area.add_child(col_shape)
	add_child(contact_area)

func _physics_process(delta: float) -> void:
	if is_being_raped:
		velocity = Vector2.ZERO
		return

	if current_state == State.DEAD:
		_dead(delta)
		return

	# Process timers if alive
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	# Knockback processing (shared from Actor)
	if knockback_timer > 0.0:
		if is_attacking_state:
			is_attacking_state = false # Interrupt attack on hit/knockback
			if has_node("Sprite2D"):
				$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
			queue_redraw()
		if current_state == State.ATTRACTED:
			knockback_timer = 0.0
		else:
			knockback_timer -= delta
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			if not is_on_floor():
				velocity.y += gravity * delta
			move_and_slide()
			return

	if is_attacking_state:
		attack_active_timer -= delta
		velocity.x = 0.0
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()

		# Active damage window check
		var time_elapsed = attack_duration - attack_active_timer
		
		# Telegraphing visual: flash/modulate red during wind-up
		if has_node("Sprite2D"):
			if time_elapsed < attack_damage_window_start:
				var flash = int(time_elapsed * 15.0) % 2 == 0
				$Sprite2D.modulate = Color(1.0, 0.3, 0.3, 1.0) if flash else Color(1.0, 0.8, 0.8, 1.0)
			else:
				# Restore standard modulate for active frames and recovery
				if current_state == State.DEAD:
					$Sprite2D.modulate = Color(0.5, 0.5, 0.5, 1.0)
				else:
					$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)

		if time_elapsed >= attack_damage_window_start and time_elapsed <= attack_damage_window_end:
			if not has_dealt_damage_this_attack and player_ref and is_instance_valid(player_ref) and player_ref.current_state != player_ref.State.DEFEATED:
				var player_pos = player_ref.global_position
				var attack_center_x = global_position.x + direction * 38.0
				var attack_center_y = global_position.y + 9.0

				var dx = abs(player_pos.x - attack_center_x)
				var dy = abs(player_pos.y - attack_center_y)
				# 40x68 px bounding box overlay check
				if dx <= 20.0 + 16.0 and dy <= 34.0 + 30.0:
					player_ref.take_damage(contact_damage, global_position, self)
					has_dealt_damage_this_attack = true
					print("[ENEMY ATTACK] ", name, " hit player for ", contact_damage, " damage!")

		if attack_active_timer <= 0.0:
			is_attacking_state = false
			if has_node("Sprite2D"):
				$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)

		queue_redraw()
		return

	match current_state:
		State.PATROL: _patrol(delta)
		State.CHASE:  _chase(delta)
		State.DEAD:   _dead(delta)
		State.ATTRACTED: _attracted(delta)

# ── PATROL ──────────────────────────────────────────────────────────────────
func _patrol(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	# Transition → CHASE if player is within radius
	if player_ref and global_position.distance_to(player_ref.global_position) <= chase_radius:
		current_state = State.CHASE
		attack_cooldown_timer = 0.8 # Initial reaction delay when spotting player
		return

	var should_flip := false
	wall_ray.target_position.x = direction * wall_raycast_length
	wall_ray.force_raycast_update()
	if wall_ray.is_colliding():
		should_flip = true

	if is_on_floor():
		if direction == 1 and not edge_right.is_colliding():
			should_flip = true
		elif direction == -1 and not edge_left.is_colliding():
			should_flip = true

	if should_flip:
		direction = -direction
		if has_node("Sprite2D"):
			$Sprite2D.flip_h = direction < 0

	velocity.x = direction * patrol_speed
	move_and_slide()
	_apply_contact_damage()

# ── CHASE ───────────────────────────────────────────────────────────────────
func _chase(delta: float) -> void:
	if not player_ref:
		current_state = State.PATROL
		return

	var dist := global_position.distance_to(player_ref.global_position)

	# Return to patrol when player escapes radius
	if dist > chase_radius:
		current_state = State.PATROL
		return

	# If within attack range, trigger attack
	if dist <= attack_range and attack_cooldown_timer <= 0.0 and not is_attacking_state:
		is_attacking_state = true
		attack_active_timer = attack_duration
		attack_cooldown_timer = attack_cooldown
		has_dealt_damage_this_attack = false
		velocity.x = 0.0
		# Face player
		var dx := player_ref.global_position.x - global_position.x
		direction = 1 if dx > 0 else -1
		if has_node("Sprite2D"):
			$Sprite2D.flip_h = direction < 0
		print("[ENEMY ATTACK] Triggered attack on player.")
		queue_redraw()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	# Move towards player horizontally
	var dx := player_ref.global_position.x - global_position.x
	direction = 1 if dx > 0 else -1
	if has_node("Sprite2D"):
		$Sprite2D.flip_h = direction < 0

	var move_direction := direction
	var current_speed := chase_speed
	
	# Maintain combat distance during cooldown to prevent collision contact damage spam
	if attack_cooldown_timer > 0.0:
		var retreat_threshold = attack_range + 10.0 # 70px
		var stop_threshold = attack_range + 35.0    # 95px
		
		if dist < retreat_threshold:
			# Too close! Back away slowly (opposite of player direction)
			move_direction = -direction
			current_speed = patrol_speed * 0.8
		elif dist <= stop_threshold:
			# In the sweet spot, stand still and wait
			move_direction = 0
			current_speed = 0.0
		else:
			# Too far, close the gap slowly
			move_direction = direction
			current_speed = chase_speed * 0.7

	# Simple wall-jump: if blocked by wall and player is above, jump
	if move_direction != 0:
		wall_ray.target_position.x = move_direction * wall_raycast_length
		wall_ray.force_raycast_update()
		if wall_ray.is_colliding() and is_on_floor():
			var dy := player_ref.global_position.y - global_position.y
			if dy < jump_height_threshold:
				velocity.y = -wall_jump_force

	velocity.x = move_direction * current_speed
	move_and_slide()
	_apply_contact_damage()

# ── DEAD (Corpse) ────────────────────────────────────────────────────────────
func _dead(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = 0
	move_and_slide()

# ── HELPERS ─────────────────────────────────────────────────────────────────
func _apply_contact_damage() -> void:
	if not contact_area:
		return
		
	# Physics-offloaded overlap check:
	for body in contact_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			if body.current_state != body.State.DEFEATED:
				# contact damage is halved (reduced to half)
				body.take_damage(int(round(contact_damage * 0.5)), global_position, self)

# ── DEATH (override Actor.die) ───────────────────────────────────────────────
func die() -> void:
	current_state = State.DEAD
	is_attacking_state = false
	queue_redraw()

	# Remove enemy collision; keep floor collision so corpse doesn't fall through
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 1)
	
	# Disable the damage hitbox
	if contact_area:
		contact_area.queue_free()
		contact_area = null

	# Turn gray (corpse visual)
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.5, 0.5, 0.5, 1.0)

	print("GrabEnemy died → CORPSE state")
	
	# Award player Skill Point (SP)
	if player_ref and player_ref.skill_component:
		player_ref.skill_component.skill_points += sp_gain
		print("[COMBAT] Enemy defeated! Player gains ", sp_gain, " Skill Point (SP: ", player_ref.skill_component.skill_points, ")")

	# Dynamically create a pickup Area2D for the key
	call_deferred("_create_pickup_key_area")

func _create_pickup_key_area() -> void:
	var area := Area2D.new()
	area.name = "CorpseArea"

	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = key_pickup_radius
	shape_node.shape = circle
	area.add_child(shape_node)

	add_child(area)
	area.body_entered.connect(_on_corpse_body_entered)

func _on_corpse_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("collect_key"):
		body.collect_key(key_name_to_drop)
		# Fade-out and free corpse
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.35)
		tw.finished.connect(queue_free)

func is_alive() -> bool:
	return current_state != State.DEAD

# ── ATTRACTED ────────────────────────────────────────────────────────────────
func _attracted(delta: float) -> void:
	if not player_ref:
		current_state = State.PATROL
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	# Move towards player horizontally
	var dx := player_ref.global_position.x - global_position.x
	direction = 1 if dx > 0 else -1
	if has_node("Sprite2D"):
		$Sprite2D.flip_h = direction < 0

	var speed_mult := 0.5
	var effect = get_node_or_null("AttractEffectComponent")
	if effect and "speed_multiplier" in effect:
		speed_mult = effect.speed_multiplier

	velocity.x = direction * (chase_speed * speed_mult)
	move_and_slide()
	_apply_contact_damage()

# Override take_damage to support double damage and bypass knockback when attracted
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO, attacker: Node2D = null) -> void:
	if current_state == State.DEAD:
		return
		
	var final_amount = amount
	if current_state == State.ATTRACTED:
		var is_in_h_scene = is_being_raped
		if is_instance_valid(attacker) and attacker is Player:
			if attacker.current_state == Player.State.GRABBED or attacker.current_state == Player.State.RAPE:
				is_in_h_scene = true
		
		if not is_in_h_scene:
			final_amount = amount * 2
		super(final_amount, Vector2.ZERO, attacker)
		return

	# Check if hit during attack wind-up (charge phase)
	if is_attacking_state:
		var time_elapsed = attack_duration - attack_active_timer
		if time_elapsed < attack_damage_window_start:
			# Wind-up phase: 20% chance to disrupt (reset wind-up)
			if randf() < 0.20:
				# Reset wind-up to start
				attack_active_timer = attack_duration
				has_dealt_damage_this_attack = false
				print("[COMBAT] ", name, " wind-up disrupted! Resetting charge.")
				# Play a quick visual cue (flash bright white briefly)
				if has_node("Sprite2D"):
					$Sprite2D.modulate = Color(2.0, 2.0, 2.0, 1.0)
					var t = create_tween()
					t.tween_property($Sprite2D, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.1)
				# Deal damage but NO knockback (pass Vector2.ZERO)
				super(final_amount, Vector2.ZERO, attacker)
				queue_redraw()
				return
			else:
				# 80% chance: ignore interrupt (super armor), deal damage but NO knockback
				print("[COMBAT] ", name, " ignored interrupt during wind-up (super armor).")
				super(final_amount, Vector2.ZERO, attacker)
				return
		else:
			# During active/recovery frames, let it be interrupted normally
			super(final_amount, source_position, attacker)
			return

	super(final_amount, source_position, attacker)

func _draw() -> void:
	if is_attacking_state:
		var is_facing_left = direction < 0
		var x_pos = -58.0 if is_facing_left else 18.0
		# Draw the attack rectangle (orange/red overlay)
		draw_rect(Rect2(x_pos, -25.0, 40.0, 68.0), Color(0.85, 0.45, 0.15, 0.6))
