extends Node2D

var progress: float = 0.0
var max_progress: float = 100.0
var next_key: String = "any" # "left", "right", or "any"
var shake_amount: float = 0.0

func _process(delta: float) -> void:
	if not visible:
		return
		
	# Giảm chấn rung lắc theo thời gian
	if shake_amount > 0.0:
		shake_amount = move_toward(shake_amount, 0.0, delta * 30.0)
		
	# Gọi draw lại mỗi frame để đảm bảo animation mượt mà
	queue_redraw()

func set_qte_state(prog: float, max_prog: float, next: String, shake: float = 0.0) -> void:
	progress = prog
	max_progress = max_prog
	next_key = next
	if shake > 0.0:
		shake_amount = shake

func _draw() -> void:
	# Áp dụng độ lệch rung lắc
	var shake_offset = Vector2.ZERO
	if shake_amount > 0.0:
		shake_offset = Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
		
	var time = Time.get_ticks_msec() * 0.008
	
	# Vẽ thanh tiến trình nền (Black flat bar)
	var bar_width = 50.0
	var bar_height = 6.0
	var bar_rect = Rect2(-bar_width * 0.5 + shake_offset.x, -bar_height * 0.5 + shake_offset.y, bar_width, bar_height)
	draw_rect(bar_rect, Color(0.08, 0.05, 0.12, 0.85), true) # Nền tím tối mờ
	draw_rect(bar_rect, Color(0.85, 0.15, 0.15), false, 1.0) # Viền đỏ cảnh báo
	
	# Vẽ thanh tiến trình nạp đầy (Red fill)
	if progress > 0.0:
		var fill_width = (progress / max_progress) * bar_width
		var fill_rect = Rect2(-bar_width * 0.5 + shake_offset.x, -bar_height * 0.5 + shake_offset.y, fill_width, bar_height)
		draw_rect(fill_rect, Color(0.9, 0.2, 0.2), true)
		
	# Vẽ mũi tên Trái (Left Arrow) - vị trí X = -38
	var left_arrow_center = Vector2(-38.0, 0.0) + shake_offset
	var left_highlighted = (next_key == "left" or next_key == "any")
	var left_color = Color(0.1, 0.6, 1.0) if left_highlighted else Color(0.15, 0.3, 0.5, 0.4)
	var left_scale = 1.0 + (0.15 * abs(sin(time))) if left_highlighted else 0.85
	
	_draw_arrow(left_arrow_center, -1.0, left_scale, left_color)
	
	# Vẽ mũi tên Phải (Right Arrow) - vị trí X = 38
	var right_arrow_center = Vector2(38.0, 0.0) + shake_offset
	var right_highlighted = (next_key == "right" or next_key == "any")
	var right_color = Color(0.1, 0.6, 1.0) if right_highlighted else Color(0.15, 0.3, 0.5, 0.4)
	var right_scale = 1.0 + (0.15 * abs(sin(time + PI))) if right_highlighted else 0.85
	
	_draw_arrow(right_arrow_center, 1.0, right_scale, right_color)

# Hàm vẽ mũi tên phụ trợ
func _draw_arrow(center: Vector2, direction: float, scale_val: float, color: Color) -> void:
	var points = PackedVector2Array()
	if direction > 0:
		# Mũi tên hướng sang phải
		points.append(Vector2(6, 0))
		points.append(Vector2(-1, -6))
		points.append(Vector2(-1, -2.5))
		points.append(Vector2(-7, -2.5))
		points.append(Vector2(-7, 2.5))
		points.append(Vector2(-1, 2.5))
		points.append(Vector2(-1, 6))
	else:
		# Mũi tên hướng sang trái
		points.append(Vector2(-6, 0))
		points.append(Vector2(1, -6))
		points.append(Vector2(1, -2.5))
		points.append(Vector2(7, -2.5))
		points.append(Vector2(7, 2.5))
		points.append(Vector2(1, 2.5))
		points.append(Vector2(1, 6))
		
	# Áp dụng tỉ lệ và vị trí
	for i in range(points.size()):
		points[i] = center + points[i] * scale_val
		
	# Vẽ khối đa giác mũi tên
	draw_polygon(points, [color])
	
	# Vẽ viền màu trắng để mũi tên nổi bật trên nền tối
	var outline_color = Color(1, 1, 1, 0.9) if color.a > 0.5 else Color(0.6, 0.6, 0.6, 0.3)
	var outline_points = PackedVector2Array(points)
	outline_points.append(points[0])
	draw_polyline(outline_points, outline_color, 1.0)
