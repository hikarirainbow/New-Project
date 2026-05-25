@tool
extends Area2D

func _ready():
	# Chỉ kết nối tín hiệu khi đang trong màn chơi chạy thực tế (không phải trong Editor)
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)

func _draw():
	# Vẽ hình tròn màu xanh lá (Green circle) làm vật phẩm nâng cấp
	# Bán kính 12px (Đường kính 24px) để nhỏ nhắn và cân đối
	draw_circle(Vector2.ZERO, 12.0, Color(0.15, 0.85, 0.15, 1.0))
	
	# Vẽ thêm một viền đen mỏng xung quanh để hiển thị sắc nét hơn
	draw_arc(Vector2.ZERO, 12.0, 0, TAU, 32, Color(0.05, 0.05, 0.05, 1.0), 2.0)

# Xử lý khi Player đi xuyên qua vật phẩm
func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("upgrade_dash_cooldown"):
			body.upgrade_dash_cooldown()
			# Xóa vật phẩm khỏi màn hình sau khi thu thập
			queue_free()
