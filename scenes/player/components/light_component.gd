class_name LightComponent
extends Node2D

@export var texture_scale: float = 2.5
@export var shadow_color: Color = Color(0, 0, 0, 0.7)

func _ready() -> void:
	_setup_light()

func _setup_light() -> void:
	var light = PointLight2D.new()
	light.name = "PlayerLight"
	
	# Tạo texture dạng hình tròn chuyển sắc mịn màng (smoothstep) từ trắng sang trong suốt
	var gradient = Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_LINEAR
	
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	
	# Sinh các điểm trung gian tạo đường cong mờ dần tự nhiên theo khoảng cách
	for i in range(1, 10):
		var t = i / 10.0
		var alpha = 1.0 - (3.0 * t * t - 2.0 * t * t * t)
		gradient.add_point(t, Color(1.0, 1.0, 1.0, alpha))
	
	var grad_tex = GradientTexture2D.new()
	grad_tex.gradient = gradient
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(1.0, 0.5)
	grad_tex.width = 384
	grad_tex.height = 384
	
	light.texture = grad_tex
	light.texture_scale = texture_scale
	light.shadow_enabled = true
	light.shadow_filter = PointLight2D.SHADOW_FILTER_PCF5
	light.shadow_color = shadow_color
	light.range_item_cull_mask = 1  # Chỉ chiếu sáng thực thể ở Layer 1
	light.shadow_item_cull_mask = 3  # Đổ bóng từ cả Layer 1 và Layer 2
	add_child(light)
