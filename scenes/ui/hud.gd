extends CanvasLayer

@onready var health_bar = $Control/MarginContainer/VBoxContainer/HealthBar
@onready var health_label = $Control/MarginContainer/VBoxContainer/HealthLabel

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
