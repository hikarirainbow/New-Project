extends CharacterBody2D

# Các thông số di chuyển cơ bản (phù hợp với game platformer 2D)
const SPEED = 200.0
const JUMP_VELOCITY = -380.0
const ACCELERATION = 1000.0
const FRICTION = 1200.0

# Trọng lực mặc định của Godot
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Trạng thái nhân vật (FSM)
enum State { MOVE, GRABBED, DEFEATED, DASH }
var current_state = State.MOVE

# Hệ thống máu và Debuff
var max_health = 100
var current_health = 100
var is_debuffed = false
var knockback_timer = 0.0

# Các thông số của kỹ năng Dash (Lướt nhanh)
const DASH_SPEED = SPEED * 3.0 # Tốc độ lướt gấp 3 lần bình thường (600 px/s)
const DASH_DURATION = 0.2 # Tổng thời gian lướt (0.2 giây)
const DASH_ACTIVE_DURATION = 0.18 # 9/10 thời gian đầu (0.18s) là lướt chủ động & miễn sát thương
var dash_cooldown = 0.8 # Thời gian hồi chiêu (dạng biến để có thể nâng cấp)
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = Vector2.ZERO
var is_invincible = false

# Tín hiệu phát đi khi máu thay đổi hoặc khi chết
signal health_changed(new_health)
signal player_defeated

var spawn_point: Vector2

func _ready():
	add_to_group("player")
	spawn_point = global_position

func _physics_process(delta):
	# Giảm thời gian hồi chiêu lướt
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		
	if knockback_timer > 0.0:
		knockback_timer -= delta
		
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
	# Kích hoạt Dash (lướt nhanh) khi nhấn Shift (nút 'dash') và hết thời gian hồi chiêu
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		start_dash()
		return

	# Áp dụng trọng lực
	if not is_on_floor():
		# Nếu nhân vật đang rơi xuống, tăng trọng lực để rơi nhanh hơn (giúp nhảy có cảm giác nặng hơn)
		var active_gravity = gravity * 1.5 if velocity.y > 0 else gravity
		velocity.y += active_gravity * delta

	# Nếu đang chịu lực giật lùi (knockback), khóa phím điều khiển và giảm tốc dần
	if knockback_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		move_and_slide()
		return

	# Nhảy
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
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

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
		
		# Lấy tốc độ đích sau khi kết thúc lướt (tùy vào phím bấm hiện tại của người chơi)
		var target_speed = Input.get_axis("move_left", "move_right") * SPEED
		
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

# Nhận sát thương và chịu đẩy lùi
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO):
	if current_state == State.DEFEATED or is_invincible:
		return
		
	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health)
	
	# Nếu có vị trí nguồn sát thương và chưa chết, áp dụng giật lùi
	if source_position != Vector2.ZERO and current_health > 0:
		apply_knockback(source_position)
	
	if current_health <= 0:
		die()

# Áp dụng lực giật lùi
func apply_knockback(source_position: Vector2, force: float = 250.0):
	if current_state == State.DEFEATED:
		return
	# Tính hướng đẩy lùi ngược lại nguồn gây sát thương
	var direction = (global_position - source_position).normalized()
	# Nếu sát thương thẳng đứng, chọn hướng đẩy ngang ngẫu nhiên
	if abs(direction.x) < 0.1:
		direction.x = 1.0 if randf() > 0.5 else -1.0
	velocity.x = direction.x * force
	velocity.y = -180.0 # Nảy nhẹ lên
	knockback_timer = 0.25 # Khóa phím trong 0.25 giây

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
