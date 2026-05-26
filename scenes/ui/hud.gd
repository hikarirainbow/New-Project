extends CanvasLayer

@onready var health_bar   = $Control/MarginContainer/VBoxContainer/HealthBar
@onready var health_label = $Control/MarginContainer/VBoxContainer/HealthLabel
@onready var key_label    = $Control/MarginContainer/VBoxContainer/KeyLabel
@onready var screen_fade  = $Control/ScreenFade

# QTE UI Member Variables
var qte_container: PanelContainer = null
var qte_bar: ProgressBar = null
var qte_prompt: Label = null
var qte_shake_intensity: float = 0.0

func _ready():
	add_to_group("hud")
	# Khởi tạo khung UI QTE
	_create_qte_ui()
	
	# Đợi một frame để chắc chắn rằng Player đã được khởi tạo trong Scene Tree
	await get_tree().process_frame
	
	# Tìm nhân vật Player trong group "player"
	var player = get_tree().get_first_node_in_group("player")
	if player:
		setup_player(player)
	else:
		print("HUD: Không tìm thấy Player trong scene!")

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

func _process(delta: float) -> void:
	if qte_container and qte_container.visible:
		# Hiệu ứng nhấp nháy/pulse phóng to thu nhỏ nhẹ cho dòng chữ
		var time = Time.get_ticks_msec() * 0.008
		var scale_val = 0.95 + 0.1 * abs(sin(time))
		qte_prompt.scale = Vector2(scale_val, scale_val)
		qte_prompt.pivot_offset = qte_prompt.size * 0.5
		
		# Hiệu ứng rung lắc (shake)
		if qte_shake_intensity > 0.0:
			qte_shake_intensity = move_toward(qte_shake_intensity, 0.0, delta * 30.0)
			var offset_x = randf_range(-qte_shake_intensity, qte_shake_intensity)
			var offset_y = randf_range(-qte_shake_intensity, qte_shake_intensity)
			qte_container.position = Vector2((640 - 250) * 0.5 + offset_x, 270 + offset_y)
		else:
			qte_container.position = Vector2((640 - 250) * 0.5, 270)

func _create_qte_ui() -> void:
	qte_container = PanelContainer.new()
	qte_container.name = "QTEContainer"
	qte_container.visible = false
	qte_container.custom_minimum_size = Vector2(250, 60)
	
	# Custom style cho Panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.12, 0.85) # Tím tối mờ
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.85, 0.15, 0.15, 1.0) # Đỏ cảnh báo
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	qte_container.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	qte_container.add_child(vbox)
	
	qte_prompt = Label.new()
	qte_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qte_prompt.text = "[SPAM A - D ĐỂ THOÁT!]"
	qte_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	qte_prompt.add_theme_constant_override("outline_size", 4)
	qte_prompt.add_theme_font_size_override("font_size", 12)
	vbox.add_child(qte_prompt)
	
	qte_bar = ProgressBar.new()
	qte_bar.show_percentage = false
	qte_bar.custom_minimum_size = Vector2(200, 12)
	
	# Custom background cho ProgressBar
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.2, 0.1, 0.1, 1.0)
	bar_bg.corner_radius_top_left = 4
	bar_bg.corner_radius_top_right = 4
	bar_bg.corner_radius_bottom_right = 4
	bar_bg.corner_radius_bottom_left = 4
	qte_bar.add_theme_stylebox_override("background", bar_bg)
	
	# Custom fill cho ProgressBar
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.9, 0.2, 0.2, 1.0) # Đỏ tươi sáng
	bar_fill.corner_radius_top_left = 4
	bar_fill.corner_radius_top_right = 4
	bar_fill.corner_radius_bottom_right = 4
	bar_fill.corner_radius_bottom_left = 4
	qte_bar.add_theme_stylebox_override("fill", bar_fill)
	
	vbox.add_child(qte_bar)
	
	# Thêm vào node Control có sẵn của HUD
	var control = get_node_or_null("Control")
	if control:
		control.add_child(qte_container)
		
	qte_container.anchors_preset = Control.LayoutPreset.PRESET_CENTER_BOTTOM
	qte_container.position = Vector2((640 - 250) * 0.5, 270)

func show_qte(max_val: float) -> void:
	if not qte_container:
		return
	qte_container.visible = true
	qte_bar.max_value = max_val
	qte_bar.value = 0.0
	qte_shake_intensity = 0.0

func update_qte(val: float) -> void:
	if qte_bar:
		qte_bar.value = val

func trigger_qte_shake() -> void:
	qte_shake_intensity = 8.0 # Rung lắc khi người chơi nhấn nút thành công

func hide_qte() -> void:
	if qte_container:
		qte_container.visible = false
