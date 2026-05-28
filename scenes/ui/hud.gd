extends CanvasLayer

@onready var health_bar   = $Control/MarginContainer/VBoxContainer/HealthBar
@onready var health_label = $Control/MarginContainer/VBoxContainer/HealthLabel
@onready var sanity_bar   = $Control/MarginContainer/VBoxContainer/SanityBar
@onready var sanity_label = $Control/MarginContainer/VBoxContainer/SanityLabel
@onready var key_label    = $Control/MarginContainer/VBoxContainer/KeyLabel
@onready var screen_fade  = $Control/ScreenFade

var _corruption_node = null
var vignette_rect: TextureRect = null
var flash_rect: ColorRect = null

func _ready():
	add_to_group("hud")
	
	# Đợi một frame để chắc chắn rằng Player đã được khởi tạo trong Scene Tree
	await get_tree().process_frame
	
	# Tìm nhân vật Player trong group "player"
	var player = get_tree().get_first_node_in_group("player")
	if player:
		setup_player(player)
	else:
		print("HUD: Không tìm thấy Player trong scene!")
		
	# Programmatically instantiate and add EruptionIndicator
	var eruption_script = load("res://scenes/ui/eruption_indicator.gd")
	if eruption_script:
		var indicator = Control.new()
		indicator.name = "EruptionIndicator"
		indicator.set_script(eruption_script)
		$Control.add_child(indicator)
		print("HUD: Programmatically added EruptionIndicator")
		
	# Programmatically instantiate and add DebugOverlay
	var debug_script = load("res://scenes/ui/debug_overlay.gd")
	if debug_script:
		var debug_overlay = Control.new()
		debug_overlay.name = "DebugOverlay"
		debug_overlay.set_script(debug_script)
		$Control.add_child(debug_overlay)
		print("HUD: Programmatically added DebugOverlay")
		
	# Programmatically create and add Vignette (dark purple-red edges)
	vignette_rect = TextureRect.new()
	vignette_rect.name = "Vignette"
	vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	var gradient = Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CUBIC
	gradient.set_color(0, Color(0.0, 0.0, 0.0, 0.0))
	gradient.set_color(1, Color(0.18, 0.02, 0.08, 0.85))
	
	var grad_tex = GradientTexture2D.new()
	grad_tex.gradient = gradient
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(1.0, 1.0)
	
	vignette_rect.texture = grad_tex
	vignette_rect.modulate.a = 0.0 # start invisible
	$Control.add_child(vignette_rect)
	print("HUD: Programmatically added Vignette")
	
	# Programmatically create and add Screen Flash ColorRect
	flash_rect = ColorRect.new()
	flash_rect.name = "ScreenFlash"
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(1.0, 0.5, 0.75, 0.0) # Pinkish white, initially invisible
	$Control.add_child(flash_rect)
	print("HUD: Programmatically added ScreenFlash")

# Thiết lập giá trị ban đầu cho thanh máu và kết nối Signal
func setup_player(player):
	health_bar.max_value = player.max_health
	health_bar.value = player.current_health
	update_label(player.current_health, player.max_health)
	
	# Kết nối tín hiệu thay đổi máu từ Player để cập nhật UI
	if player.health_changed.is_connected(_on_player_health_changed):
		player.health_changed.disconnect(_on_player_health_changed)
	player.health_changed.connect(_on_player_health_changed)
	
	# Kết nối tín hiệu khi Player bị tiêu diệt
	if player.player_defeated.is_connected(_on_player_defeated):
		player.player_defeated.disconnect(_on_player_defeated)
	player.player_defeated.connect(_on_player_defeated)
	
	# Kết nối tín hiệu khi Player nhặt chìa khóa
	if player.key_collected.is_connected(_on_key_collected):
		player.key_collected.disconnect(_on_key_collected)
	player.key_collected.connect(_on_key_collected)

	# Thiết lập giá trị ban đầu và kết nối tín hiệu Sanity từ CorruptionComponent
	if player.has_node("CorruptionComponent"):
		_corruption_node = player.get_node("CorruptionComponent")
		sanity_bar.max_value = 100.0
		sanity_bar.value = _corruption_node.sanity
		_update_sanity_ui(_corruption_node.sanity)
		if _corruption_node.sanity_changed.is_connected(_on_player_sanity_changed):
			_corruption_node.sanity_changed.disconnect(_on_player_sanity_changed)
		_corruption_node.sanity_changed.connect(_on_player_sanity_changed)

# Xử lý sự kiện khi máu Player thay đổi (nhận sát thương hoặc hồi máu)
func _on_player_health_changed(new_health):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Sử dụng Tween để làm mượt chuyển động rút máu của thanh UI (tăng trải nghiệm cao cấp)
		var tween = create_tween()
		tween.tween_property(health_bar, "value", new_health, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		update_label(new_health, player.max_health)

# Cập nhật text hiển thị số lượng máu HP: X / Y
func update_label(current, maximum):
	health_label.text = "HP: %d / %d" % [current, maximum]

# Xử lý sự kiện khi Sanity thay đổi
func _on_player_sanity_changed(new_sanity):
	var tween = create_tween()
	tween.tween_property(sanity_bar, "value", new_sanity, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_update_sanity_ui(new_sanity)

# Cập nhật nhãn và thay đổi màu sắc chuyển màu (Sacred Gold -> Demonic Purple)
func _update_sanity_ui(sanity_val: float):
	var max_sanity_val = 100.0
	if _corruption_node:
		max_sanity_val = _corruption_node.max_sanity
	sanity_label.text = "Sanity: %d / %d" % [int(round(sanity_val)), int(round(max_sanity_val))]
	var fill_stylebox = sanity_bar.get_theme_stylebox("fill").duplicate()
	if fill_stylebox is StyleBoxFlat:
		# Gold = Color(0.9, 0.8, 0.2)
		# Purple = Color(0.5, 0.1, 0.8)
		var color = Color(0.5, 0.1, 0.8).lerp(Color(0.9, 0.8, 0.2), sanity_val / 100.0)
		fill_stylebox.bg_color = color
	sanity_bar.add_theme_stylebox_override("fill", fill_stylebox)
	
	# Dynamically update vignette opacity based on sanity (lower sanity -> stronger vignette border)
	if vignette_rect:
		var sanity_ratio = sanity_val / 100.0
		var target_alpha = lerp(0.85, 0.0, sanity_ratio) # range from 0.0 at full sanity to 0.85 at zero sanity
		var tween = create_tween()
		tween.tween_property(vignette_rect, "modulate:a", target_alpha, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# Fade out the screen to black
func fade_to_black(duration: float = 0.15) -> Tween:
	var fade_tween = create_tween()
	fade_tween.tween_property(screen_fade, "color", Color(0, 0, 0, 1), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return fade_tween

# Fade in the screen to transparent
func fade_from_black(duration: float = 0.15) -> Tween:
	var fade_tween = create_tween()
	fade_tween.tween_property(screen_fade, "color", Color(0, 0, 0, 0), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	return fade_tween

# Xử lý sự kiện khi nhân vật bị đánh bại hoàn toàn (hiệu ứng chuyển màn hình đen và hồi sinh)
func _on_player_defeated():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
		
	# 1. Làm tối đen màn hình (Fade to Black)
	await fade_to_black(0.5).finished
	
	# 2. Hồi sinh nhân vật (đưa về spawn point, phục hồi HP đã debuff)
	player.respawn()
	
	# Chờ thêm một khoảng ngắn để người chơi định hình
	await get_tree().create_timer(0.2).timeout
	
	# 3. Làm sáng lại màn hình (Fade to Transparent)
	fade_from_black(0.5)

# Cập nhật HUD khi Player nhặt chìa khóa
func _on_key_collected(key_name: String):
	var player = get_tree().get_first_node_in_group("player")
	if player and player.keys.size() > 0:
		key_label.text = "Keys: " + ", ".join(player.keys)
	else:
		key_label.text = "Keys: None"

func trigger_flash(color: Color = Color(1.0, 0.5, 0.75, 0.25), duration: float = 0.15) -> void:
	if flash_rect:
		flash_rect.color = Color(color.r, color.g, color.b, color.a)
		var tween = create_tween()
		tween.tween_property(flash_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
