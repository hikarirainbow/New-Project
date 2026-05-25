@tool
extends Area2D

# Sát thương kẻ địch tĩnh gây ra
@export var damage: int = 15

# Cấu hình mặt nạ bóng tối (Shadow Shroud) trực tiếp qua Inspector
@export_group("Shadow Shroud")
@export_range(0.0, 1.0) var shadow_shroud_unlit_alpha: float = 0.0:
	set(val):
		shadow_shroud_unlit_alpha = val
		if is_inside_tree():
			_update_shadow_shroud_material()

@export var shadow_shroud_unlit_color: Color = Color.BLACK:
	set(val):
		shadow_shroud_unlit_color = val
		if is_inside_tree():
			_update_shadow_shroud_material()

var player_ref: Node = null
var is_in_dark: bool = false

func _ready():
	# Chỉ kết nối tín hiệu khi đang trong màn chơi chạy thực tế (không phải trong Editor)
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		
		# Áp dụng ShaderMaterial ẩn quái vật trong bóng tối cho kẻ địch tĩnh
		var shader = load("res://scenes/enemies/enemy_shadow_shroud.gdshader")
		var mat = ShaderMaterial.new()
		mat.shader = shader
		self.material = mat
		_update_shadow_shroud_material()

func _update_shadow_shroud_material():
	if self.material is ShaderMaterial:
		self.material.set_shader_parameter("unlit_alpha", shadow_shroud_unlit_alpha)
		self.material.set_shader_parameter("unlit_color", shadow_shroud_unlit_color)
		self.material.set_shader_parameter("is_in_dark", is_in_dark)

func _physics_process(_delta):
	if Engine.is_editor_hint():
		return
		
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("player")
		
	_update_darkness_state()

func _update_darkness_state():
	if not player_ref:
		is_in_dark = true
		_apply_darkness_shader_param()
		return
		
	var dist = global_position.distance_to(player_ref.global_position)
	if dist > 360.0:
		is_in_dark = true
	else:
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(player_ref.global_position, global_position, 1)
		var result = space_state.intersect_ray(query)
		if result:
			is_in_dark = true
		else:
			is_in_dark = false
			
	_apply_darkness_shader_param()

func _apply_darkness_shader_param():
	if self.material is ShaderMaterial:
		self.material.set_shader_parameter("is_in_dark", is_in_dark)

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
			body.take_damage(damage, global_position)

# Nhận sát thương khi bị Player tấn công
func take_damage(amount: int):
	print("Kẻ địch bị đánh! Nhận sát thương: ", amount)
