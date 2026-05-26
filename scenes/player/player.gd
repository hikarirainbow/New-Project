class_name Player
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

# Cấu hình thời gian bất tử khi bị tấn công
@export var damage_invincibility_duration: float = 0.5
var invincibility_timer = 0.0
var is_invincible = false

# Tín hiệu đặc thù phát đi khi người chơi chết
signal player_defeated
# Tín hiệu phát khi nhặt chìa khóa
signal key_collected(key_name: String)

# Kho lưu trữ chìa khóa
var keys: Array[String] = []
var spawn_point: Vector2

# Caching component references
@onready var attack_component = $AttackComponent
@onready var dash_component = $DashComponent

func _ready():
	add_to_group("player")
	spawn_point = global_position
	if has_node("Camera2D"): $Camera2D.zoom = Vector2(1.2, 1.2)
	# Ẩn và khóa chuột vào màn hình khi bắt đầu chơi game
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	if knockback_timer > 0.0:
		knockback_timer -= delta
		
	# Đếm ngược thời gian bất tử và nhấp nháy sprite
	if invincibility_timer > 0.0:
		invincibility_timer -= delta
		if has_node("Sprite2D"):
			$Sprite2D.modulate.a = 0.4 if Engine.get_frames_drawn() % 10 < 5 else 1.0
		if invincibility_timer <= 0.0:
			is_invincible = false
			if has_node("Sprite2D"):
				$Sprite2D.modulate.a = 1.0
			
	match current_state:
		State.MOVE:
			handle_move_state(delta)
		State.GRABBED:
			handle_grabbed_state(delta)
		State.DEFEATED:
			handle_defeated_state(delta)
		State.DASH:
			dash_component.process_dash(delta)

# Logic trạng thái di chuyển tự do
func handle_move_state(delta):
	# Nếu đang tấn công, khóa điều khiển/hướng và dừng lại trên mặt đất
	if attack_component.is_attacking():
		if is_on_floor():
			velocity.x = 0.0
		if not is_on_floor():
			var active_gravity = gravity * 1.5 if velocity.y > 0 else gravity
			velocity.y += active_gravity * delta
		move_and_slide()
		return

	# Kích hoạt Tấn công khi nhấn phím X (nút 'attack') và không đang tấn công
	if Input.is_action_just_pressed("attack") and attack_component.can_attack():
		attack_component.start_attack()
		return

	# Kích hoạt Dash (lướt nhanh) khi nhấn Shift (nút 'dash') và hết thời gian hồi chiêu
	if Input.is_action_just_pressed("dash") and dash_component.can_dash():
		dash_component.start_dash()
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
	attack_component.interrupt()
	dash_component.interrupt()
		
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
	dash_component.reset()

# Nâng cấp kỹ năng lướt: Giảm một nửa thời gian hồi chiêu
func upgrade_dash_cooldown():
	dash_component.upgrade_cooldown()

# Thu thập chìa khóa từ xác quái vật
func collect_key(key_name: String):
	keys.append(key_name)
	emit_signal("key_collected", key_name)
	print("Key collected: ", key_name, " | Total keys: ", keys)
