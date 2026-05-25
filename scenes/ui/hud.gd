extends CanvasLayer

@onready var health_bar = $Control/MarginContainer/VBoxContainer/HealthBar
@onready var health_label = $Control/MarginContainer/VBoxContainer/HealthLabel
@onready var screen_fade = $Control/ScreenFade

func _ready():
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
	player.health_changed.connect(_on_player_health_changed)
	# Kết nối tín hiệu khi Player bị tiêu diệt
	player.player_defeated.connect(_on_player_defeated)

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

# Xử lý sự kiện khi nhân vật bị đánh bại hoàn toàn (hiệu ứng chuyển màn hình đen và hồi sinh)
func _on_player_defeated():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
		
	# 1. Làm tối đen màn hình (Fade to Black)
	var fade_tween = create_tween()
	fade_tween.tween_property(screen_fade, "color", Color(0, 0, 0, 1), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Đợi hiệu ứng fade hoàn thành
	await fade_tween.finished
	
	# 2. Hồi sinh nhân vật (đưa về spawn point, phục hồi HP đã debuff)
	player.respawn()
	
	# Chờ thêm một khoảng ngắn để người chơi định hình
	await get_tree().create_timer(0.2).timeout
	
	# 3. Làm sáng lại màn hình (Fade to Transparent)
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(screen_fade, "color", Color(0, 0, 0, 0), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
