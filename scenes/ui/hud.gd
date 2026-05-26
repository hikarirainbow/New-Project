extends CanvasLayer

@onready var health_bar   = $Control/MarginContainer/VBoxContainer/HealthBar
@onready var health_label = $Control/MarginContainer/VBoxContainer/HealthLabel
@onready var key_label    = $Control/MarginContainer/VBoxContainer/KeyLabel
@onready var screen_fade  = $Control/ScreenFade

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
