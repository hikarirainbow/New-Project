@tool
extends Area2D

# Sát thương kẻ địch tĩnh gây ra
@export var damage: int = 15

# Cấu hình ngưỡng ánh sáng hiển thị trực tiếp qua Inspector (0.0 = nhạy nhất, 1.0 = tắt)
@export_group("Shadow Shroud")
@export_range(0.0, 1.0) var shadow_shroud_light_threshold: float = 0.05:
	set(val):
		shadow_shroud_light_threshold = val
		if is_inside_tree():
			_update_shadow_shroud_material()

func _ready():
	# Chỉ kết nối tín hiệu khi đang trong màn chơi chạy thực tế (không phải trong Editor)
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)

func _update_shadow_shroud_material():
	if self.material is ShaderMaterial:
		self.material.set_shader_parameter("light_threshold", shadow_shroud_light_threshold)

func _draw():
	# Vẽ một hạt đậu đỏ (red bean shape) có kích thước 32x32 (bằng một nửa chiều cao Player)
	# Sử dụng StyleBoxFlat để bo tròn góc và đổ màu đỏ mượt mà trong màn hình vẽ vector
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.85, 0.15, 0.15, 1.0) # Màu đỏ nổi bật
	style_box.corner_radius_top_left = 16
	style_box.corner_radius_top_right = 16
	style_box.corner_radius_bottom_right = 16
	style_box.corner_radius_bottom_left = 16
	
	# Vẽ căn giữa tại gốc tọa độ (0, 0)
	draw_style_box(style_box, Rect2(-16, -16, 32, 32))

# Xử lý khi Player đi vào vùng nguy hiểm của kẻ địch tĩnh
func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			# Gây sát thương và truyền vị trí của kẻ địch để Player tính toán hướng đẩy lùi (Knockback)
			body.take_damage(damage, global_position, self)

# Nhận sát thương khi bị Player tấn công
func take_damage(amount: int):
	print("Kẻ địch bị đánh! Nhận sát thương: ", amount)
