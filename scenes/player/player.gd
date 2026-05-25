extends CharacterBody2D

# Các thông số di chuyển cơ bản (phù hợp với game platformer 2D)
const SPEED = 200.0
const JUMP_VELOCITY = -380.0
const ACCELERATION = 1000.0
const FRICTION = 1200.0

# Trọng lực mặc định của Godot
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Trạng thái nhân vật (FSM)
enum State { MOVE, GRABBED, DEFEATED }
var current_state = State.MOVE

# Hệ thống máu và Debuff
var max_health = 100
var current_health = 100
var is_debuffed = false

# Tín hiệu phát đi khi máu thay đổi hoặc khi chết
signal health_changed(new_health)
signal player_defeated

func _ready():
	add_to_group("player")

func _physics_process(delta):
	match current_state:
		State.MOVE:
			handle_move_state(delta)
		State.GRABBED:
			handle_grabbed_state(delta)
		State.DEFEATED:
			handle_defeated_state(delta)

# Logic trạng thái di chuyển tự do
func handle_move_state(delta):
	# Áp dụng trọng lực
	if not is_on_floor():
		# Nếu nhân vật đang rơi xuống, tăng trọng lực để rơi nhanh hơn (giúp nhảy có cảm giác nặng hơn)
		var active_gravity = gravity * 1.5 if velocity.y > 0 else gravity
		velocity.y += active_gravity * delta

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

# Nhận sát thương
func take_damage(amount: int):
	if current_state == State.DEFEATED:
		return
		
	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health)
	
	if current_health <= 0:
		die()

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
