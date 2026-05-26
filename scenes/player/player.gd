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

# Biến trạng thái QTE (Quick Time Event)
var qte_progress: float = 0.0
var qte_target: float = 100.0
var last_qte_key: String = ""
var _force_triple_knockback: bool = false

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
	# Áp dụng trọng lực
	if not is_on_floor():
		var active_gravity = gravity * 1.5 if velocity.y > 0 else gravity
		velocity.y += active_gravity * delta

	# Giảm tốc độ ngang dần khi knockback trôi qua
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	move_and_slide()
	
	# Suy giảm tiến trình QTE theo thời gian (decay)
	qte_progress = max(0.0, qte_progress - delta * 15.0)
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_qte(qte_progress)
		
	# Kiểm tra nút nhấn spam di chuyển (A / D hoặc Mũi tên Trái / Phải)
	var left_pressed = Input.is_action_just_pressed("move_left")
	var right_pressed = Input.is_action_just_pressed("move_right")
	
	if left_pressed or right_pressed:
		var valid_input = false
		if left_pressed and last_qte_key != "left":
			last_qte_key = "left"
			valid_input = true
		elif right_pressed and last_qte_key != "right":
			last_qte_key = "right"
			valid_input = true
			
		if valid_input:
			qte_progress = min(qte_target, qte_progress + 10.0)
			if hud:
				hud.update_qte(qte_progress)
				hud.trigger_qte_shake()
				
	# Nếu đã đủ tiến trình thoát khỏi khống chế
	if qte_progress >= qte_target:
		current_state = State.MOVE
		if hud:
			hud.hide_qte()
		# Cho người chơi 0.5 giây bất tử để thoát đi an toàn
		is_invincible = true
		invincibility_timer = 0.5
		if has_node("Sprite2D"):
			$Sprite2D.modulate.a = 1.0

# Bắt đầu trạng thái QTE
func start_qte():
	current_state = State.GRABBED
	qte_progress = 0.0
	last_qte_key = ""
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_qte(qte_target)

# Ghi đè hàm apply_knockback từ Actor để hỗ trợ knockback QTE mạnh gấp 3 lần
func apply_knockback(source_position: Vector2, force: float = 250.0):
	var actual_force = force
	var actual_upward = -180.0
	var actual_duration = 0.25
	
	if _force_triple_knockback:
		actual_force = force * 3.0
		actual_upward = -350.0  # Phóng bay mạnh hơn lên trên
		actual_duration = 0.5   # Khóa phím điều khiển lâu hơn trong lúc bay
		
	var direction = (global_position - source_position).normalized()
	if abs(direction.x) < 0.1:
		direction.x = 1.0 if randf() > 0.5 else -1.0
	velocity.x = direction.x * actual_force
	velocity.y = actual_upward
	knockback_timer = actual_duration

# Logic khi bị đánh bại hoàn toàn (Defeated)
func handle_defeated_state(delta):
	# Nếu đang lơ lửng trên không thì rơi xuống đất
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = 0
	move_and_slide()

# Nhận sát thương và chịu đẩy lùi (Ghi đè lớp cha Actor để thêm miễn nhiễm)
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO):
	if current_state == State.DEFEATED or current_state == State.GRABBED or is_invincible:
		return
		
	# Ngắt đòn đánh hoặc lướt khi trúng đòn
	attack_component.interrupt()
	dash_component.interrupt()
	
	var is_below_half_hp = current_health < max_health * 0.5
	var would_survive = (current_health - amount) > 0
	var should_trigger_qte = is_below_half_hp and would_survive
	
	if should_trigger_qte:
		_force_triple_knockback = true
		
	super(amount, source_position)
	
	if should_trigger_qte:
		_force_triple_knockback = false
		start_qte()
	else:
		# Kích hoạt trạng thái bất tử sau khi nhận sát thương nếu không bị QTE
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
	
	# Đảm bảo ẩn thanh QTE nếu có khi hồi sinh
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.hide_qte()

# Nâng cấp kỹ năng lướt: Giảm một nửa thời gian hồi chiêu
func upgrade_dash_cooldown():
	dash_component.upgrade_cooldown()

# Thu thập chìa khóa từ xác quái vật
func collect_key(key_name: String):
	keys.append(key_name)
	emit_signal("key_collected", key_name)
	print("Key collected: ", key_name, " | Total keys: ", keys)
