extends Actor

# Tốc độ di chuyển tuần tra của quái vật
const SPEED = 60.0
const CONTACT_DAMAGE = 15

# Bộ máy trạng thái (FSM) cơ bản
enum State { PATROL, DEAD }
var current_state = State.PATROL

# Hướng di chuyển: 1 = Phải, -1 = Trái
var direction = 1

# Các node con RayCast dò tìm tường và hố sâu
@onready var edge_detector_right = $RayCast2D_EdgeRight
@onready var edge_detector_left = $RayCast2D_EdgeLeft
@onready var wall_detector = $RayCast2D_Wall

func _physics_process(delta):
	# Nếu đang bị giật lùi (knockback), để lực đẩy tự tiêu hao
	if knockback_timer > 0.0:
		knockback_timer -= delta
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return

	match current_state:
		State.PATROL:
			handle_patrol_state(delta)
		State.DEAD:
			handle_dead_state(delta)

# Xử lý logic trạng thái tuần tra (PATROL)
func handle_patrol_state(delta):
	# Áp dụng trọng lực
	if not is_on_floor():
		velocity.y += gravity * delta

	# Kiểm tra xem có cần quay đầu (gặp tường hoặc mép vực) không
	var should_flip = false

	# 1. Dò tường phía trước hướng đi
	wall_detector.target_position.x = direction * 24.0
	wall_detector.force_raycast_update()
	if wall_detector.is_colliding():
		should_flip = true

	# 2. Dò mép hố (vực sâu) để quay đầu tránh bị rơi xuống
	if is_on_floor():
		if direction == 1 and not edge_detector_right.is_colliding():
			should_flip = true
		elif direction == -1 and not edge_detector_left.is_colliding():
			should_flip = true

	# Quay đầu nếu thỏa mãn điều kiện
	if should_flip:
		direction = -direction
		# Lật hình ảnh Sprite
		if has_node("Sprite2D"):
			$Sprite2D.flip_h = direction < 0

	# Di chuyển theo hướng hiện tại
	velocity.x = direction * SPEED
	move_and_slide()

	# Xử lý va chạm: Nếu đâm trúng Player, gây sát thương
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(CONTACT_DAMAGE, global_position)

# Xử lý logic trạng thái chết (DEAD)
func handle_dead_state(delta):
	# Chỉ rơi xuống đất nếu đang ở trên không trung
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = 0
	move_and_slide()

# Ghi đè hàm die() của Actor
func die():
	current_state = State.DEAD
	
	# Vô hiệu hóa va chạm với Player (chỉ giữ lại va chạm nền đất để không rơi xuyên map)
	collision_layer = 0
	collision_mask = 1
	
	print("Kẻ địch tuần tra đã chết!")
	
	# Hiệu ứng tan biến dần (fade-out)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	# Tự giải phóng bộ nhớ sau khi tan biến xong
	tween.finished.connect(queue_free)
