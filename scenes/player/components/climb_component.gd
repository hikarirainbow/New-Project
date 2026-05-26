class_name ClimbComponent
extends Node2D

const CLIMB_DURATION = 0.5

var climb_start_pos: Vector2
var climb_target_pos: Vector2
var climb_timer: float = 0.0

@onready var player = get_parent()

# Lấy thông tin mép tường tự động sửa sai vị trí (Auto-Correction Ledge Check)
func check_ledge() -> Dictionary:
	if player.is_on_floor():
		return {}
		
	var space_state = player.get_world_2d().direct_space_state
	var facing_dir = -1.0 if (player.has_node("Sprite2D") and player.get_node("Sprite2D").flip_h) else 1.0
	
	# 1. Bắn tia ngang ở đầu gối/hông (Y = 16) - phải va chạm vật thể
	var lower_start = player.global_position + Vector2(0, 16)
	var lower_end = lower_start + Vector2(facing_dir * 20, 0)
	var query_lower = PhysicsRayQueryParameters2D.create(lower_start, lower_end, 1)
	query_lower.exclude = [player.get_rid()]
	var result_lower = space_state.intersect_ray(query_lower)
	
	if result_lower.is_empty():
		return {}
		
	# 2. Bắn tia ngang ở ngực/đầu (Y = -16) - phải trống (đầu vượt qua mép)
	var upper_start = player.global_position + Vector2(0, -16)
	var upper_end = upper_start + Vector2(facing_dir * 20, 0)
	var query_upper = PhysicsRayQueryParameters2D.create(upper_start, upper_end, 1)
	query_upper.exclude = [player.get_rid()]
	var result_upper = space_state.intersect_ray(query_upper)
	
	if not result_upper.is_empty():
		return {}
		
	# 3. Tính toán mép trên của gạch bằng cách bắn tia dọc từ trên xuống
	var wall_x = result_lower.position.x
	var check_top_start = Vector2(wall_x + facing_dir * 4, result_lower.position.y - 24)
	var check_top_end = Vector2(wall_x + facing_dir * 4, result_lower.position.y + 24)
	var query_top = PhysicsRayQueryParameters2D.create(check_top_start, check_top_end, 1)
	query_top.exclude = [player.get_rid()]
	var result_top = space_state.intersect_ray(query_top)
	
	if result_top.is_empty():
		return {}
		
	var ledge_top_y = result_top.position.y
	
	# Vị trí đích sau khi leo cách mép tile một khoảng nhỏ
	var target_pos = Vector2(wall_x + facing_dir * 15.0, ledge_top_y - 32.0)
	
	# 4. Kiểm tra xem vị trí đứng sau khi leo có bị cản trở/kẹt trần hay không
	var query_clear = PhysicsRayQueryParameters2D.create(target_pos, target_pos + Vector2(0, -30), 1)
	query_clear.exclude = [player.get_rid()]
	var result_clear = space_state.intersect_ray(query_clear)
	if not result_clear.is_empty():
		return {}
		
	return {
		"target_position": target_pos,
		"start_position": player.global_position
	}

# Bắt đầu hoạt cảnh leo
func start_climb(target_pos: Vector2) -> void:
	player.current_state = Player.State.CLIMB
	climb_start_pos = player.global_position
	climb_target_pos = target_pos
	climb_timer = 0.0
	player.velocity = Vector2.ZERO
	
	# Ngắt đòn đánh và lướt
	if player.has_node("AttackComponent"):
		player.get_node("AttackComponent").interrupt()
	if player.has_node("DashComponent"):
		player.get_node("DashComponent").interrupt()
		
	# Tắt va chạm với gạch tạm thời để tránh glitch kẹt tường
	player.set_collision_mask_value(1, false)

# Xử lý hoạt cảnh leo hình chữ L (L-shaped LERP)
func process_climb(delta: float) -> void:
	climb_timer += delta
	var t = climb_timer / CLIMB_DURATION
	t = clamp(t, 0.0, 1.0)
	
	# Leo hình chữ L (L-shaped LERP): Lên trước, tiến sau
	if t < 0.5:
		var ratio = t / 0.5
		var ease_ratio = sin(ratio * PI * 0.5)
		player.global_position.y = lerp(climb_start_pos.y, climb_target_pos.y, ease_ratio)
		player.global_position.x = climb_start_pos.x
		# Co giãn sprite tạo cảm giác nhún người leo lên
		if player.has_node("Sprite2D"):
			player.get_node("Sprite2D").scale = Vector2(0.22, 0.58)
	else:
		var ratio = (t - 0.5) / 0.5
		var ease_ratio = sin(ratio * PI * 0.5)
		player.global_position.y = climb_target_pos.y
		player.global_position.x = lerp(climb_start_pos.x, climb_target_pos.x, ease_ratio)
		if player.has_node("Sprite2D"):
			player.get_node("Sprite2D").scale = Vector2(0.28, 0.42)
			
	if climb_timer >= CLIMB_DURATION:
		# Kết thúc hoạt cảnh leo tường
		player.global_position = climb_target_pos
		if player.has_node("Sprite2D"):
			player.get_node("Sprite2D").scale = Vector2(0.25, 0.5) # Khôi phục scale gốc
		player.set_collision_mask_value(1, true) # Bật lại va chạm gạch
		player.current_state = Player.State.MOVE

# Ngắt leo
func interrupt() -> void:
	if player.current_state == Player.State.CLIMB:
		player.set_collision_mask_value(1, true)
		if player.has_node("Sprite2D"):
			player.get_node("Sprite2D").scale = Vector2(0.25, 0.5)
		player.current_state = Player.State.MOVE
