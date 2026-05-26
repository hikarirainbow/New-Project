extends Actor

# Các thông số di chuyển cơ bản (phù hợp với game platformer 2D)
const SPEED           = 200.0
const JUMP_VELOCITY   = -450.0  # ~103px apex
const ACCELERATION    = 1000.0

# Trạng thái nhân vật (FSM)
enum State { MOVE, GRABBED, DEFEATED, DASH }
var current_state = State.MOVE

# Trạng thái suy yếu (Debuff) đặc thù của Player
var is_debuffed = false

# Các thông số của kỹ năng Dash (Lướt nhanh)
const DASH_SPEED = SPEED * 3.0 # Tốc độ lướt gấp 3 lần bình thường (600 px/s)
const DASH_DURATION = 0.2 # Tổng thời gian lướt (0.2 giây)
const DASH_ACTIVE_DURATION = 0.18 # 9/10 thời gian đầu (0.18s) là lướt chủ động & miễn sát thương
var dash_cooldown = 0.8 # Thời gian hồi chiêu (dạng biến để có thể nâng cấp)
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = Vector2.ZERO
var is_invincible = false

# Các thông số của kỹ năng Attack (Tấn công)
const ATTACK_DURATION = 0.15 # 150ms để hoạt cảnh đánh mượt hơn
var attack_timer = 0.0
@onready var attack_area_collision = $AttackArea/CollisionShape2D
var attack_shape_2: CollisionShape2D # Shape phụ trên đầu cho đòn combo nhịp 2
var current_combo_index = 0
var combo_index = 0
var combo_reset_timer = 0.0
const COMBO_RESET_DELAY = 0.5 # Thời gian tối đa để bấm nối combo tiếp theo (500ms)
var bodies_hit_this_attack: Array[Node] = []

# Cấu hình thời gian bất tử khi bị tấn công
@export var damage_invincibility_duration: float = 0.5
var invincibility_timer = 0.0

# Tín hiệu đặc thù phát đi khi người chơi chết
signal player_defeated
# Tín hiệu phát khi nhặt chìa khóa
signal key_collected(key_name: String)

# Kho lưu trữ chìa khóa
var keys: Array[String] = []

var spawn_point: Vector2

func _ready():
	add_to_group("player")
	spawn_point = global_position
	if has_node("Camera2D"): $Camera2D.zoom = Vector2(1.2, 1.2)
	if has_node("AttackArea"):
		$AttackArea.body_entered.connect(_on_attack_body_entered)
		
		# Khởi tạo shape phụ cho combo đòn 2 dynamically
		attack_shape_2 = CollisionShape2D.new()
		var rect2 = RectangleShape2D.new()
		attack_shape_2.shape = rect2
		attack_shape_2.disabled = true
		$AttackArea.add_child(attack_shape_2)
		
	# Ẩn và khóa chuột vào màn hình khi bắt đầu chơi game
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Tạo ánh sáng phát sáng cho nhân vật
	_setup_player_light()

func _physics_process(delta):
	# Giảm thời gian hồi chiêu lướt
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		
	if knockback_timer > 0.0:
		knockback_timer -= delta
		
	if attack_timer > 0.0:
		attack_timer -= delta
		queue_redraw()
		if attack_timer <= 0.0:
			end_attack()
			
	# Đếm ngược thời gian bất tử và nhấp nháy sprite
	if invincibility_timer > 0.0:
		invincibility_timer -= delta
		if has_node("Sprite2D"):
			$Sprite2D.modulate.a = 0.4 if Engine.get_frames_drawn() % 10 < 5 else 1.0
		if invincibility_timer <= 0.0:
			is_invincible = false
			if has_node("Sprite2D"):
				$Sprite2D.modulate.a = 1.0
			
	# Đếm ngược thời gian chờ để nối combo tiếp theo
	if combo_reset_timer > 0.0 and attack_timer <= 0.0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0.0:
			combo_index = 0 # Reset về nhịp 1 nếu quá thời gian chờ
		
	match current_state:
		State.MOVE:
			handle_move_state(delta)
		State.GRABBED:
			handle_grabbed_state(delta)
		State.DEFEATED:
			handle_defeated_state(delta)
		State.DASH:
			handle_dash_state(delta)

# Logic trạng thái di chuyển tự do
func handle_move_state(delta):
	# Nếu đang tấn công, khóa điều khiển/hướng và dừng lại trên mặt đất
	if attack_timer > 0.0:
		if is_on_floor():
			velocity.x = 0.0
		if not is_on_floor():
			var active_gravity = gravity * 1.5 if velocity.y > 0 else gravity
			velocity.y += active_gravity * delta
		move_and_slide()
		return

	# Kích hoạt Tấn công khi nhấn phím X (nút 'attack') và không đang tấn công
	if Input.is_action_just_pressed("attack") and attack_timer <= 0.0:
		start_attack()
		return

	# Kích hoạt Dash (lướt nhanh) khi nhấn Shift (nút 'dash') và hết thời gian hồi chiêu
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		start_dash()
		return

	# Áp dụng trọng lực
	if not is_on_floor():
		# Nếu nhân vật đang rơi xuống, tăng trọng lực để rơi nhanh hơn (giúp nhảy có cảm giác nặng hơn)
		var active_gravity = gravity * 1.5 if velocity.y > 0 else gravity
		velocity.y += active_gravity * delta

	# Variable jump height: nếu nhả phím jump sớm trong khi đang bay lên, giảm vận tốc đi lên mạnh để đạt min jump cực thấp (~5px)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.1

	# Nếu đang chịu lực giật lùi (knockback), khóa phím điều khiển và giảm tốc dần
	if knockback_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		move_and_slide()
		return

	# Nhảy (sử dụng lực tối đa — thả phím sớm để nhảy thấp hơn)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Lấy hướng nhập từ bàn phím A/D hoặc Trái/Phải
	var direction = Input.get_axis("move_left", "move_right")
	if direction != 0:
		# Tăng tốc độ dần đều đến tốc độ tối đa
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		# Quay mặt Sprite nhân vật theo hướng đi
		if has_node("Sprite2D"):
			$Sprite2D.flip_h = direction < 0
	else:
		# Giảm tốc độ dần đều về 0 khi không nhấn phím di chuyển
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	move_and_slide()

# Bắt đầu trạng thái Dash
func start_dash():
	current_state = State.DASH
	dash_timer = 0.0
	dash_cooldown_timer = dash_cooldown
	
	# Xác định hướng lướt dựa trên phím di chuyển đang giữ
	var dir = Input.get_axis("move_left", "move_right")
	if dir == 0.0:
		# Nếu không giữ nút di chuyển nào, lướt theo hướng nhân vật đang quay mặt
		dir = -1.0 if (has_node("Sprite2D") and $Sprite2D.flip_h) else 1.0
	
	dash_direction = Vector2(dir, 0.0).normalized()
	
	# Quay mặt Sprite nhân vật theo hướng lướt
	if has_node("Sprite2D"):
		$Sprite2D.flip_h = dash_direction.x < 0
		
	velocity.x = dash_direction.x * DASH_SPEED
	velocity.y = 0.0 # Khóa vận tốc nhảy/rơi theo phương dọc khi đang lướt chủ động
	is_invincible = true

# Xử lý logic trạng thái lướt (DASH)
func handle_dash_state(delta):
	dash_timer += delta
	
	if dash_timer < DASH_ACTIVE_DURATION:
		# 9/10 đoạn đầu: Di chuyển nhanh tối đa & Miễn sát thương
		velocity.x = dash_direction.x * DASH_SPEED
		velocity.y = 0.0
		is_invincible = true
	elif dash_timer < DASH_DURATION:
		# 1/10 đoạn cuối: Giảm tốc độ mượt mà về tốc độ gốc và mất miễn sát thương
		is_invincible = false
		
		# Khóa hướng di chuyển: Chỉ cho phép di chuyển tiếp theo hướng lướt nếu người giữ đúng hướng đó
		var input_dir = Input.get_axis("move_left", "move_right")
		var target_speed = 0.0
		if sign(input_dir) == sign(dash_direction.x):
			target_speed = dash_direction.x * SPEED
		
		# Tính toán tỷ lệ phần trăm tiến trình trong đoạn cuối (0.0 đến 1.0)
		var recovery_time_passed = dash_timer - DASH_ACTIVE_DURATION
		var total_recovery_time = DASH_DURATION - DASH_ACTIVE_DURATION # 0.05s
		var t = recovery_time_passed / total_recovery_time
		
		# Nội suy tuyến tính (Lerp) vận tốc ngang từ tốc độ lướt về tốc độ mục tiêu
		velocity.x = lerp(dash_direction.x * DASH_SPEED, target_speed, t)
		
		# Áp dụng trọng lực trở lại để tránh lơ lửng không tự nhiên
		if not is_on_floor():
			velocity.y += gravity * delta
	else:
		# Kết thúc thời gian lướt: quay về trạng thái di chuyển thường
		is_invincible = false
		current_state = State.MOVE
		
	move_and_slide()

# Logic khi bị khống chế (Grabbed)
func handle_grabbed_state(delta):
	# Dừng mọi chuyển động vật lý, quái vật sẽ kéo hoặc đè Player
	velocity = Vector2.ZERO

# Logic khi bị đánh bại hoàn toàn (Defeated)
func handle_defeated_state(delta):
	# Nếu đang lơ lửng trên không thì rơi xuống đất
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = 0
	move_and_slide()

# Nhận sát thương và chịu đẩy lùi (Ghi đè lớp cha Actor để thêm miễn nhiễm)
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO):
	if current_state == State.DEFEATED or is_invincible:
		return
		
	# Ngắt đòn đánh hoặc lướt khi trúng đòn
	if attack_timer > 0.0:
		end_attack()
	if current_state == State.DASH:
		current_state = State.MOVE
		
	super(amount, source_position)
	
	# Kích hoạt trạng thái bất tử sau khi nhận sát thương
	if current_health > 0:
		is_invincible = true
		invincibility_timer = damage_invincibility_duration

# Đánh bại nhân vật
func die():
	current_state = State.DEFEATED
	emit_signal("player_defeated")
	print("Player has been defeated!")

# Áp dụng hiệu ứng Debuff sau khi hồi sinh
func apply_debuff():
	is_debuffed = true
	max_health = 80
	current_health = min(current_health, max_health)
	emit_signal("health_changed", current_health)

# Xóa hiệu ứng Debuff (khi lưu game/hồi phục)
func remove_debuff():
	is_debuffed = false
	max_health = 100
	current_health = max_health
	emit_signal("health_changed", current_health)

# Hồi sinh nhân vật về điểm spawn ban đầu
func respawn():
	global_position = spawn_point
	velocity = Vector2.ZERO
	knockback_timer = 0.0
	invincibility_timer = 0.0
	is_invincible = false
	if has_node("Sprite2D"):
		$Sprite2D.modulate.a = 1.0
	current_health += 9999
	apply_debuff()
	current_state = State.MOVE

# Nâng cấp kỹ năng lướt: Giảm một nửa thời gian hồi chiêu
func upgrade_dash_cooldown():
	dash_cooldown = dash_cooldown / 2.0
	print("Dash cooldown upgraded! New cooldown: ", dash_cooldown)

# Thu thập chìa khóa từ xác quái vật
func collect_key(key_name: String):
	keys.append(key_name)
	emit_signal("key_collected", key_name)
	print("Key collected: ", key_name, " | Total keys: ", keys)

# Bắt đầu kỹ năng tấn công cận chiến với cơ chế Combo 3 nhịp biến thiên hình dáng
func start_attack():
	current_combo_index = combo_index
	attack_timer = ATTACK_DURATION
	combo_reset_timer = 0.0 # Tạm dừng reset timer trong khi đang đánh
	bodies_hit_this_attack.clear()
	
	# Hướng quay mặt của nhân vật
	var is_facing_left = $Sprite2D.flip_h if has_node("Sprite2D") else false
	
	if attack_area_collision and attack_area_collision.shape:
		# Kích hoạt hitbox chính
		attack_area_collision.disabled = false
		
		match current_combo_index:
			0: # Đòn 1: 40x50 trước mặt
				attack_area_collision.shape.size = Vector2(40.0, 50.0)
				attack_area_collision.position.x = -36.0 if is_facing_left else 36.0
				attack_area_collision.position.y = 0.0
				if attack_shape_2:
					attack_shape_2.disabled = true
					
			1: # Đòn 2: 40x50 trước mặt và 70x40 trên đầu
				# Hình trước mặt (40x50)
				attack_area_collision.shape.size = Vector2(40.0, 50.0)
				attack_area_collision.position.x = -36.0 if is_facing_left else 36.0
				attack_area_collision.position.y = 0.0
				
				# Hình trên đầu (70x40)
				if attack_shape_2 and attack_shape_2.shape:
					attack_shape_2.disabled = false
					attack_shape_2.shape.size = Vector2(70.0, 40.0)
					attack_shape_2.position.x = 0.0
					attack_shape_2.position.y = -52.0
					
			2: # Đòn 3: 50x30 trước mặt (đòn đâm/chém xa)
				attack_area_collision.shape.size = Vector2(50.0, 30.0)
				attack_area_collision.position.x = -41.0 if is_facing_left else 41.0
				attack_area_collision.position.y = 0.0
				if attack_shape_2:
					attack_shape_2.disabled = true
	queue_redraw()

# Kết thúc kỹ năng tấn công
func end_attack():
	if attack_area_collision:
		attack_area_collision.disabled = true
	if attack_shape_2:
		attack_shape_2.disabled = true
	
	# Tiến tới đòn tiếp theo trong combo, reset sau khi đạt tối đa
	combo_index = (current_combo_index + 1) % 3
	combo_reset_timer = COMBO_RESET_DELAY
	queue_redraw()

# Xử lý khi rìa tấn công quét trúng Body của kẻ địch
func _on_attack_body_entered(body):
	if body.has_method("take_damage") and not bodies_hit_this_attack.has(body):
		bodies_hit_this_attack.append(body)
		body.take_damage(20, global_position) # Gây 20 sát thương lên kẻ địch

# Vẽ hiệu ứng hitbox chỉ báo visual khác màu nhau cho mỗi nhịp
func _draw():
	if attack_timer > 0.0:
		var is_facing_left = $Sprite2D.flip_h if has_node("Sprite2D") else false
		match current_combo_index:
			0: # Đòn 1: Vẽ hình chữ nhật màu xanh dương 40x50
				var x_pos = -56.0 if is_facing_left else 16.0
				draw_rect(Rect2(x_pos, -25.0, 40.0, 50.0), Color(0.15, 0.15, 0.85, 0.6))
			1: # Đòn 2: Vẽ hình trước mặt và trên đầu màu xanh lá
				var x_pos = -56.0 if is_facing_left else 16.0
				draw_rect(Rect2(x_pos, -25.0, 40.0, 50.0), Color(0.15, 0.85, 0.15, 0.6))
				draw_rect(Rect2(-35.0, -52.0, 70.0, 40.0), Color(0.15, 0.85, 0.15, 0.6))
			2: # Đòn 3: Vẽ hình 50x30 màu đỏ
				var x_pos = -66.0 if is_facing_left else 16.0
				draw_rect(Rect2(x_pos, -15.0, 50.0, 30.0), Color(0.85, 0.15, 0.15, 0.6))

# Thiết lập PointLight2D phát sáng
func _setup_player_light():
	var light = PointLight2D.new()
	light.name = "PlayerLight"
	
	# Tạo texture dạng hình tròn chuyển sắc mịn màng (smoothstep) từ trắng sang trong suốt
	var gradient = Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_LINEAR
	
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	
	# Sinh các điểm trung gian tạo đường cong mờ dần tự nhiên theo khoảng cách
	for i in range(1, 10):
		var t = i / 10.0
		var alpha = 1.0 - (3.0 * t * t - 2.0 * t * t * t)
		gradient.add_point(t, Color(1.0, 1.0, 1.0, alpha))
	
	var grad_tex = GradientTexture2D.new()
	grad_tex.gradient = gradient
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(1.0, 0.5)
	grad_tex.width = 384
	grad_tex.height = 384
	
	light.texture = grad_tex
	light.texture_scale = 2.5  # Tầm nhìn lớn gấp 2.5 lần hiện tại
	light.shadow_enabled = true
	light.shadow_filter = PointLight2D.SHADOW_FILTER_PCF5
	light.shadow_color = Color(0, 0, 0, 0.7)
	light.range_item_cull_mask = 1  # Chỉ chiếu sáng thực thể ở Layer 1 (Player, Enemy, BG)
	light.shadow_item_cull_mask = 3  # Đổ bóng từ cả Layer 1 và Layer 2 (MapTile)
	add_child(light)
