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
const ATTACK_DURATION = 0.1
var attack_timer = 0.0
@onready var attack_area_collision = $AttackArea/CollisionShape2D

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
	if has_node("AttackArea"):
		$AttackArea.body_entered.connect(_on_attack_body_entered)
	# Ẩn và khóa chuột vào màn hình khi bắt đầu chơi game
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
	super(amount, source_position)

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

# Bắt đầu kỹ năng tấn công cận chiến
func start_attack():
	attack_timer = ATTACK_DURATION
	if attack_area_collision:
		attack_area_collision.disabled = false
		# Điều chỉnh vị trí hitbox: cách tâm nhân vật 20px, dài 50px (tức tâm của hình chữ nhật cách nhân vật 20 + 25 = 45px)
		var is_facing_left = $Sprite2D.flip_h if has_node("Sprite2D") else false
		attack_area_collision.position.x = -45.0 if is_facing_left else 45.0
	queue_redraw()

# Kết thúc kỹ năng tấn công
func end_attack():
	if attack_area_collision:
		attack_area_collision.disabled = true
	queue_redraw()

# Xử lý khi rìa tấn công quét trúng Body của kẻ địch
func _on_attack_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(20, global_position) # Gây 20 sát thương lên kẻ địch

# Vẽ hiệu ứng hitbox màu xanh dương làm chỉ báo visual
func _draw():
	# Chỉ vẽ khi đang kích hoạt chiêu tấn công
	if attack_timer > 0.0:
		var is_facing_left = $Sprite2D.flip_h if has_node("Sprite2D") else false
		# Nếu quay trái, bắt đầu vẽ từ -70px (cách 20px + dài 50px). Nếu quay phải, bắt đầu từ 20px
		var x_pos = -70.0 if is_facing_left else 20.0
		# Vẽ hình chữ nhật màu xanh dương bán trong suốt cao 10px (từ Y = -5 đến 5)
		draw_rect(Rect2(x_pos, -5.0, 50.0, 10.0), Color(0.15, 0.15, 0.85, 0.6))
