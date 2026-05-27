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
	# Knockback processing (shared from Actor)
	if knockback_timer > 0.0:
		if current_state == State.ATTRACTED:
			knockback_timer = 0.0
		else:
			knockback_timer -= delta
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			if not is_on_floor():
				velocity.y += gravity * delta
			move_and_slide()
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

	if not is_on_floor():
		velocity.y += gravity * delta

	# Move towards player horizontally
	var dx := player_ref.global_position.x - global_position.x
	direction = 1 if dx > 0 else -1
	if has_node("Sprite2D"):
		$Sprite2D.flip_h = direction < 0

	# Simple wall-jump: if blocked by wall and player is above, jump
	wall_ray.target_position.x = direction * wall_raycast_length
	wall_ray.force_raycast_update()
	if wall_ray.is_colliding() and is_on_floor():
		var dy := player_ref.global_position.y - global_position.y
		if dy < jump_height_threshold:
			velocity.y = -wall_jump_force

	velocity.x = direction * chase_speed
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
				body.take_damage(contact_damage, global_position)

# ── DEATH (override Actor.die) ───────────────────────────────────────────────
func die() -> void:
	current_state = State.DEAD

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

	velocity.x = direction * (chase_speed * 0.5)
	move_and_slide()
	_apply_contact_damage()

# Override take_damage to support double damage and bypass knockback when attracted
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if current_state == State.DEAD:
		return
		
	var final_amount = amount
	if current_state == State.ATTRACTED:
		final_amount = amount * 2
		super(final_amount, Vector2.ZERO)
	else:
		super(final_amount, source_position)
