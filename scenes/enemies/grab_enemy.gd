extends Actor

const SPEED         = 60.0
const CHASE_SPEED   = 90.0
const CONTACT_DAMAGE = 15
const CHASE_RADIUS  = 100.0

enum State { PATROL, CHASE, DEAD }
var current_state = State.PATROL

var direction = 1
var player_ref: Node = null

@onready var edge_right  = $RayCast2D_EdgeRight
@onready var edge_left   = $RayCast2D_EdgeLeft
@onready var wall_ray    = $RayCast2D_Wall

# Cấu hình mặt nạ bóng tối (Shadow Shroud) trực tiếp qua Inspector
@export_group("Shadow Shroud")
@export_range(0.0, 1.0) var shadow_shroud_unlit_alpha: float = 0.0:
	set(val):
		shadow_shroud_unlit_alpha = val
		if is_inside_tree():
			_update_shadow_shroud_material()

@export var shadow_shroud_unlit_color: Color = Color.BLACK:
	set(val):
		shadow_shroud_unlit_color = val
		if is_inside_tree():
			_update_shadow_shroud_material()

func _ready():
	add_to_group("enemies")
	
	# Khởi tạo ShaderMaterial ẩn quái vật trong bóng tối
	if has_node("Sprite2D"):
		var shader = load("res://scenes/enemies/enemy_shadow_shroud.gdshader")
		var mat = ShaderMaterial.new()
		mat.shader = shader
		$Sprite2D.material = mat
		_update_shadow_shroud_material()
		
	# Cache player reference once
	await get_tree().process_frame
	player_ref = get_tree().get_first_node_in_group("player")

var is_in_dark: bool = false

func _update_shadow_shroud_material():
	if has_node("Sprite2D") and $Sprite2D.material is ShaderMaterial:
		$Sprite2D.material.set_shader_parameter("unlit_alpha", shadow_shroud_unlit_alpha)
		$Sprite2D.material.set_shader_parameter("unlit_color", shadow_shroud_unlit_color)
		$Sprite2D.material.set_shader_parameter("is_in_dark", is_in_dark)

func _update_darkness_state():
	if not player_ref:
		is_in_dark = true
		_apply_darkness_shader_param()
		return
		
	var dist = global_position.distance_to(player_ref.global_position)
	# Player PointLight2D diameter is 768px (radius 384px). We use 360px as conservative light boundary.
	if dist > 360.0:
		is_in_dark = true
	else:
		# Line-of-sight check using physics raycast against solid tiles (collision mask 1)
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(player_ref.global_position, global_position, 1)
		var result = space_state.intersect_ray(query)
		if result:
			# Ray hit a block, meaning the enemy is behind a wall/tile in shadows
			is_in_dark = true
		else:
			is_in_dark = false
			
	_apply_darkness_shader_param()

func _apply_darkness_shader_param():
	if has_node("Sprite2D") and $Sprite2D.material is ShaderMaterial:
		$Sprite2D.material.set_shader_parameter("is_in_dark", is_in_dark)

func _physics_process(delta):
	_update_darkness_state()
	
	# Knockback processing (shared from Actor)
	if knockback_timer > 0.0:
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

# ── PATROL ──────────────────────────────────────────────────────────────────
func _patrol(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	# Transition → CHASE if player is within radius
	if player_ref and global_position.distance_to(player_ref.global_position) <= CHASE_RADIUS:
		current_state = State.CHASE
		return

	var should_flip = false
	wall_ray.target_position.x = direction * 24.0
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

	velocity.x = direction * SPEED
	move_and_slide()
	_apply_contact_damage()

# ── CHASE ───────────────────────────────────────────────────────────────────
func _chase(delta):
	if not player_ref:
		current_state = State.PATROL
		return

	var dist = global_position.distance_to(player_ref.global_position)

	# Return to patrol when player escapes radius
	if dist > CHASE_RADIUS:
		current_state = State.PATROL
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	# Move towards player horizontally
	var dx = player_ref.global_position.x - global_position.x
	direction = 1 if dx > 0 else -1
	if has_node("Sprite2D"):
		$Sprite2D.flip_h = direction < 0

	# Simple wall-jump: if blocked by wall and player is above, jump
	wall_ray.target_position.x = direction * 24.0
	wall_ray.force_raycast_update()
	if wall_ray.is_colliding() and is_on_floor():
		var dy = player_ref.global_position.y - global_position.y
		if dy < -10.0:
			velocity.y = -250.0

	velocity.x = direction * CHASE_SPEED
	move_and_slide()
	_apply_contact_damage()

# ── DEAD (Corpse) ────────────────────────────────────────────────────────────
func _dead(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = 0
	move_and_slide()

# ── HELPERS ─────────────────────────────────────────────────────────────────
# Áp dụng sát thương tiếp xúc bằng cách kiểm tra khoảng cách bao quanh (bounding box) giữa quái và Player,
# do hai thực thể đã được thiết lập đi xuyên qua nhau và không sinh ra lực va chạm vật lý.
func _apply_contact_damage():
	if player_ref and player_ref.has_method("take_damage") and player_ref.current_state != player_ref.State.DEFEATED:
		var diff_x = abs(global_position.x - player_ref.global_position.x)
		var diff_y = abs(global_position.y - player_ref.global_position.y)
		# Kích thước gạch 32x32, player rộng 32 (nửa rộng 16), enemy rộng 32 (nửa rộng 16).
		# Ngưỡng tiếp xúc ngang < 30.0 và dọc < 44.0 tức là hai thực thể đang chạm/chồng lấn nhau.
		if diff_x < 30.0 and diff_y < 44.0:
			player_ref.take_damage(CONTACT_DAMAGE, global_position)

# ── DEATH (override Actor.die) ───────────────────────────────────────────────
func die():
	current_state = State.DEAD

	# Remove enemy collision; keep floor collision so corpse doesn't fall through
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 1)

	# Turn gray (corpse visual)
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.5, 0.5, 0.5, 1.0)

	print("GrabEnemy died → CORPSE state")

	# Dynamically create a pickup Area2D for the key
	var area = Area2D.new()
	area.name = "CorpseArea"

	var shape_node = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 20.0
	shape_node.shape = circle
	area.add_child(shape_node)

	add_child(area)
	area.body_entered.connect(_on_corpse_body_entered)

func _on_corpse_body_entered(body):
	if body.is_in_group("player") and body.has_method("collect_key"):
		body.collect_key("Boss Key")
		# Fade-out and free corpse
		var tw = create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.35)
		tw.finished.connect(queue_free)

func is_alive() -> bool:
	return current_state != State.DEAD
