extends CanvasLayer

@onready var menu_control = $Control
@onready var remap_container = $Control/Panel/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var mute_button = $Control/Panel/MarginContainer/VBoxContainer/HBoxExtra/MuteButton
@onready var reset_button = $Control/Panel/MarginContainer/VBoxContainer/HBoxExtra/ResetButton

var is_open = false
var remapping_action = ""
var is_muted = false

func _ready():
	# Cho phép script chạy bình thường ngay cả khi game bị pause
	process_mode = PROCESS_MODE_ALWAYS
	menu_control.visible = false
	
	# Kết nối sự kiện nút bấm phụ
	mute_button.pressed.connect(_on_mute_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	
	# Tạo danh sách các phím để remap
	setup_remap_buttons()

func _input(event):
	# Nhấn ESC để đóng/mở menu cài đặt
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_menu()
		
	# Nếu đang chờ nhập phím để thay đổi nút
	if is_open and remapping_action != "":
		if event is InputEventKey and event.is_pressed():
			var new_keycode = event.physical_keycode
			
			# Không cho phép gán nút ESC để tránh bị lỗi khóa phím hệ thống
			if new_keycode != KEY_ESCAPE:
				InputManager.remap_action(remapping_action, new_keycode)
				update_button_text(remapping_action, new_keycode)
				
			remapping_action = ""

# Đóng/mở menu cài đặt
func toggle_menu():
	is_open = !is_open
	menu_control.visible = is_open
	get_tree().paused = is_open # Dừng/Chạy game
	
	if is_open:
		# Hiện chuột khi mở Menu
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		setup_remap_buttons() # Tải lại phím bấm mới nhất
	else:
		# Ẩn chuột và khóa vào màn hình khi quay lại chơi game
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Khởi tạo các hàng phím bấm điều khiển để remap
func setup_remap_buttons():
	# Xóa các nút cũ trước khi tạo mới
	for child in remap_container.get_children():
		child.queue_free()
		
	var controls = InputManager.current_controls
	for action in controls.keys():
		# Tạo nhãn Label hiển thị tên phím (ví dụ: Move Left)
		var label = Label.new()
		label.text = action.replace("_", " ").capitalize()
		label.theme_override_colors/font_outline_color = Color(0, 0, 0, 1)
		label.theme_override_constants/outline_size = 4
		label.theme_override_font_sizes/font_size = 14
		remap_container.add_child(label)
		
		# Tạo nút bấm Button để nhấp đổi phím
		var button = Button.new()
		var keycode = controls[action]
		button.text = OS.get_keycode_string(keycode)
		button.name = action
		
		# Thiết lập giao diện nút bấm trong suốt và phẳng
		button.flat = true
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# Thiết lập StyleBox cho nút (Tạo dòng kẻ dưới khi di chuột qua - Background line)
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0, 0, 0, 0) # Nền trong suốt
		style_hover.border_width_bottom = 2 # Chỉ vẽ viền dưới
		style_hover.border_color = Color(0.2, 0.6, 1.0, 1.0) # Đường kẻ màu xanh neon
		
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0, 0, 0, 0)
		
		var style_pressed = StyleBoxFlat.new()
		style_pressed.bg_color = Color(0.2, 0.6, 1.0, 0.2)
		
		button.add_theme_stylebox_override("hover", style_hover)
		button.add_theme_stylebox_override("normal", style_normal)
		button.add_theme_stylebox_override("pressed", style_pressed)
		
		# Kết nối sự kiện khi bấm vào nút để bắt đầu lắng nghe phím mới
		button.pressed.connect(func(): start_remapping(action, button))
		remap_container.add_child(button)

# Bắt đầu chế độ chờ nhập phím mới
func start_remapping(action: String, button: Button):
	remapping_action = action
	button.text = "[ Nhấn phím bất kỳ ]"

# Cập nhật văn bản hiển thị trên nút sau khi gán phím mới
func update_button_text(action: String, keycode: int):
	var button = remap_container.get_node(action) as Button
	if button:
		button.text = OS.get_keycode_string(keycode)

# Chức năng 1: Mute/Unmute âm thanh toàn cục
func _on_mute_pressed():
	is_muted = !is_muted
	AudioServer.set_bus_mute(0, is_muted)
	mute_button.text = "Âm thanh: TẮT" if is_muted else "Âm thanh: BẬT"

# Chức năng 2: Reset cấu hình phím về mặc định
func _on_reset_pressed():
	InputManager.current_controls = InputManager.default_controls.duplicate()
	InputManager.save_controls()
	InputManager.apply_controls()
	setup_remap_buttons()
	print("Đã khôi phục cài đặt phím mặc định!")
