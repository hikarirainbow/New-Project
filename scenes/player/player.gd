class_name Player
extends Actor

# Các thông số di chuyển cơ bản (phù hợp với game platformer 2D)
const SPEED           = 200.0
const JUMP_VELOCITY   = -450.0  # ~103px apex
const ACCELERATION    = 1000.0

# Trạng thái nhân vật (FSM)
enum State { MOVE, GRABBED, DEFEATED, DASH, CLIMB }
var current_state = State.MOVE

# Các biến trạng thái leo tường/ledge climb
var climb_start_pos: Vector2
var climb_target_pos: Vector2
var climb_timer: float = 0.0
var climb_duration: float = 0.5

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
var qte_indicator: Node2D = null

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
	
	# Khởi tạo và đính kèm QTEIndicator trên đầu nhân vật (cách 50px so với đỉnh sprite)
	qte_indicator = Node2D.new()
	qte_indicator.name = "QTEIndicator"
	qte_indicator.set_script(load("res://scenes/player/qte_indicator.gd"))
	qte_indicator.visible = false
	qte_indicator.position = Vector2(0, -82) # Y = -32 (đỉnh sprite) - 50px = -82
	add_child(qte_indicator)

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
		State.CLIMB:
			handle_climb_state(delta)

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

	# Nhảy hoặc kích hoạt leo tường nếu ở trên không
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		else:
			var ledge_data = _check_ledge()
			if not ledge_data.is_empty():
				start_climb(ledge_data.target_position)
				return

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
	
	# Xác định phím kế tiếp cần spam để hướng dẫn người chơi
	var next_key = "any"
	if last_qte_key == "left":
		next_key = "right"
	elif last_qte_key == "right":
		next_key = "left"
		
	if qte_indicator:
		qte_indicator.set_qte_state(qte_progress, qte_target, next_key)
		
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
			
			var next_after_press = "any"
			if last_qte_key == "left":
				next_after_press = "right"
			elif last_qte_key == "right":
				next_after_press = "left"
				
			if qte_indicator:
				qte_indicator.set_qte_state(qte_progress, qte_target, next_after_press, 8.0)
				
	# Nếu đã đủ tiến trình thoát khỏi khống chế
	if qte_progress >= qte_target:
		current_state = State.MOVE
		if qte_indicator:
			qte_indicator.visible = false
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
	if qte_indicator:
		qte_indicator.visible = true
		qte_indicator.set_qte_state(0.0, qte_target, "any")

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

# Logic khi vật leo tường (Climb State)
func handle_climb_state(delta):
	climb_timer += delta
	var t = climb_timer / climb_duration
	t = clamp(t, 0.0, 1.0)
	
	# Leo hình chữ L (L-shaped LERP): Lên trước, tiến sau
	if t < 0.5:
		var ratio = t / 0.5
		var ease_ratio = sin(ratio * PI * 0.5)
		global_position.y = lerp(climb_start_pos.y, climb_target_pos.y, ease_ratio)
		global_position.x = climb_start_pos.x
		# Co giãn sprite tạo cảm giác nhún người leo lên
		if has_node("Sprite2D"):
			$Sprite2D.scale = Vector2(0.22, 0.58)
	else:
		var ratio = (t - 0.5) / 0.5
		var ease_ratio = sin(ratio * PI * 0.5)
		global_position.y = climb_target_pos.y
		global_position.x = lerp(climb_start_pos.x, climb_target_pos.x, ease_ratio)
		if has_node("Sprite2D"):
			$Sprite2D.scale = Vector2(0.28, 0.42)
			
	if climb_timer >= climb_duration:
		# Kết thúc hoạt cảnh leo tường
		global_position = climb_target_pos
		if has_node("Sprite2D"):
			$Sprite2D.scale = Vector2(0.25, 0.5) # Khôi phục scale gốc
		set_collision_mask_value(1, true) # Bật lại va chạm gạch
		current_state = State.MOVE

# Bắt đầu hoạt cảnh leo
func start_climb(target_pos: Vector2):
	current_state = State.CLIMB
	climb_start_pos = global_position
	climb_target_pos = target_pos
	climb_timer = 0.0
	velocity = Vector2.ZERO
	
	# Ngắt đòn đánh và lướt
	attack_component.interrupt()
	dash_component.interrupt()
	
	# Tắt va chạm với gạch tạm thời để tránh glitch kẹt tường
	set_collision_mask_value(1, false)

# Lấy thông tin mép tường tự động sửa sai vị trí (Auto-Correction Ledge Check)
func _check_ledge() -> Dictionary:
	if is_on_floor():
		return {}
		
	var space_state = get_world_2d().direct_space_state
	var facing_dir = -1.0 if (has_node("Sprite2D") and $Sprite2D.flip_h) else 1.0
	
	# 1. Bắn tia ngang ở đầu gối/hông (Y = 16) - phải va chạm vật thể
	var lower_start = global_position + Vector2(0, 16)
	var lower_end = lower_start + Vector2(facing_dir * 20, 0)
	var query_lower = PhysicsRayQueryParameters2D.create(lower_start, lower_end, 1)
	query_lower.exclude = [get_rid()]
	var result_lower = space_state.intersect_ray(query_lower)
	
	if result_lower.is_empty():
		return {}
		
	# 2. Bắn tia ngang ở ngực/đầu (Y = -16) - phải trống (đầu vượt qua mép)
	var upper_start = global_position + Vector2(0, -16)
	var upper_end = upper_start + Vector2(facing_dir * 20, 0)
	var query_upper = PhysicsRayQueryParameters2D.create(upper_start, upper_end, 1)
	query_upper.exclude = [get_rid()]
	var result_upper = space_state.intersect_ray(query_upper)
	
	if not result_upper.is_empty():
		return {}
		
	# 3. Tính toán mép trên của gạch bằng cách bắn tia dọc từ trên xuống
	var wall_x = result_lower.position.x
	var check_top_start = Vector2(wall_x + facing_dir * 4, result_lower.position.y - 24)
	var check_top_end = Vector2(wall_x + facing_dir * 4, result_lower.position.y + 24)
	var query_top = PhysicsRayQueryParameters2D.create(check_top_start, check_top_end, 1)
	query_top.exclude = [get_rid()]
	var result_top = space_state.intersect_ray(query_top)
	
	if result_top.is_empty():
		return {}
		
	var ledge_top_y = result_top.position.y
	
	# Vị trí đích an sau khi leo cách mép tile một khoảng nhỏ
	var target_pos = Vector2(wall_x + facing_dir * 15.0, ledge_top_y - 32.0)
	
	# 4. Kiểm tra xem vị trí đứng sau khi leo có bị cản trở/kẹt trần hay không
	var query_clear = PhysicsRayQueryParameters2D.create(target_pos, target_pos + Vector2(0, -30), 1)
	query_clear.exclude = [get_rid()]
	var result_clear = space_state.intersect_ray(query_clear)
	if not result_clear.is_empty():
		return {}
		
	return {
		"target_position": target_pos,
		"start_position": global_position
	}

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
	
	# Nếu bị đánh trúng khi đang leo tường, dừng leo và khôi phục va chạm
	if current_state == State.CLIMB:
		set_collision_mask_value(1, true)
		if has_node("Sprite2D"):
			$Sprite2D.scale = Vector2(0.25, 0.5)
	
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
	if qte_indicator:
		qte_indicator.visible = false

# Nâng cấp kỹ năng lướt: Giảm một nửa thời gian hồi chiêu
func upgrade_dash_cooldown():
	dash_component.upgrade_cooldown()

# Thu thập chìa khóa từ xác quái vật
func collect_key(key_name: String):
	keys.append(key_name)
	emit_signal("key_collected", key_name)
	print("Key collected: ", key_name, " | Total keys: ", keys)
