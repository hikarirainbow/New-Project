extends CanvasLayer

@onready var control_node = $Control
@onready var panel_node = $Control/Panel
@onready var map_button = $Control/Panel/MarginContainer/VBoxContainer/TabHeader/MapButton
@onready var items_button = $Control/Panel/MarginContainer/VBoxContainer/TabHeader/ItemsButton
@onready var map_page = $Control/Panel/MarginContainer/VBoxContainer/ContentContainer/MapPage
@onready var items_page = $Control/Panel/MarginContainer/VBoxContainer/ContentContainer/ItemsPage

var is_open = false
var active_tab = 0 # 0 = Map, 1 = Items

func _ready():
	# Đảm bảo UI hoạt động ngay cả khi game đang bị pause
	process_mode = PROCESS_MODE_ALWAYS
	control_node.visible = false
	
	# Kết nối sự kiện bấm nút chuyển đổi Tab
	map_button.pressed.connect(func(): switch_tab(0))
	items_button.pressed.connect(func(): switch_tab(1))
	
	# Khởi tạo style và thiết lập trạng thái mặc định
	_setup_styles()
	switch_tab(0)

func _input(event):
	# Nếu hành trang đang mở, cho phép nhấn phím Nhảy (Jump) để đóng
	if Input.is_action_just_pressed("jump") and is_open:
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return

	# Nhấn phím 'inventory' để đóng/mở hành trang
	if Input.is_action_just_pressed("inventory"):
		var settings = get_tree().current_scene.get_node_or_null("SettingsMenu")
		if settings and settings.is_open:
			return # Không cho phép mở nếu menu cài đặt đang mở
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return
		
	# Nhấn ESC để đóng hành trang nếu nó đang mở
	if Input.is_action_just_pressed("ui_cancel") and is_open:
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return
		
	# Điều hướng tab trái/phải bằng các nút di chuyển tương ứng
	if is_open:
		if Input.is_action_just_pressed("move_left"):
			switch_tab(0)
			get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("move_right"):
			switch_tab(1)
			get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("attack"):
			var active_btn = map_button if active_tab == 0 else items_button
			active_btn.pressed.emit()
			get_viewport().set_input_as_handled()

func toggle_inventory():
	is_open = !is_open
	control_node.visible = is_open
	get_tree().paused = is_open # Dừng/Chạy game
	
	if is_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		# Hiệu ứng mượt mà (Tween scale nhẹ khi mở ra)
		panel_node.scale = Vector2(0.95, 0.95)
		panel_node.pivot_offset = panel_node.size * 0.5
		var tween = create_tween()
		tween.tween_property(panel_node, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func switch_tab(tab_index: int):
	active_tab = tab_index
	map_page.visible = (tab_index == 0)
	items_page.visible = (tab_index == 1)
	
	# Cập nhật hiển thị giao diện Tab header
	_update_tab_headers()

func _update_tab_headers():
	# Style cho nút được chọn (vẽ gạch dưới màu trắng)
	var style_active = StyleBoxFlat.new()
	style_active.bg_color = Color(0, 0, 0, 0)
	style_active.border_width_bottom = 2
	style_active.border_color = Color(1.0, 1.0, 1.0, 0.9)
	
	# Style cho nút không được chọn (trong suốt hoàn toàn)
	var style_inactive = StyleBoxFlat.new()
	style_inactive.bg_color = Color(0, 0, 0, 0)
	
	map_button.add_theme_stylebox_override("normal", style_active if active_tab == 0 else style_inactive)
	items_button.add_theme_stylebox_override("normal", style_active if active_tab == 1 else style_inactive)
	
	# Đổi màu font chữ
	map_button.add_theme_color_override("font_color", Color(1, 1, 1) if active_tab == 0 else Color(0.6, 0.6, 0.6))
	items_button.add_theme_color_override("font_color", Color(1, 1, 1) if active_tab == 1 else Color(0.6, 0.6, 0.6))

func _setup_styles():
	# Thiết lập StyleBoxFlat cho Panel (Giao diện đen Acrylic viền trắng)
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.04, 0.04, 0.05, 0.9) # Nền đen mờ 90% opacity
	style_panel.border_width_left = 1
	style_panel.border_width_top = 1
	style_panel.border_width_right = 1
	style_panel.border_width_bottom = 1
	style_panel.border_color = Color(1.0, 1.0, 1.0, 0.8) # Viền trắng tinh tế
	style_panel.corner_radius_top_left = 6
	style_panel.corner_radius_top_right = 6
	style_panel.corner_radius_bottom_right = 6
	style_panel.corner_radius_bottom_left = 6
	panel_node.add_theme_stylebox_override("panel", style_panel)
	
	# Style hover cho tab button
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0, 0, 0, 0)
	style_hover.border_width_bottom = 1
	style_hover.border_color = Color(1.0, 1.0, 1.0, 0.4)
	
	var style_focus = StyleBoxEmpty.new()
	
	for btn in [map_button, items_button]:
		btn.flat = true
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("focus", style_focus)
		btn.add_theme_font_size_override("font_size", 12)
