extends Node

const SAVE_PATH: String = "user://input_config.json"

# Cấu hình nút mặc định (sử dụng physical keycodes của Godot)
var default_controls: Dictionary = {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"jump": KEY_SPACE,
	"dash": KEY_C,
	"attack": KEY_X,
	"inventory": KEY_ALT
}

var current_controls: Dictionary = {}

func _ready() -> void:
	current_controls = default_controls.duplicate()
	load_controls()

# Tải cấu hình nút từ file JSON
func load_controls() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_controls()
		apply_controls()
		return
		
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_string)
	if error == OK:
		var data = json.data
		if typeof(data) == TYPE_DICTIONARY:
			for action in data.keys():
				current_controls[action] = int(data[action])
			apply_controls()
	else:
		print("InputManager: Lỗi đọc file cấu hình: ", json.get_error_message())

# Lưu cấu hình nút vào file JSON (Atomic Write)
func save_controls() -> void:
	var temp_path := SAVE_PATH + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file:
		var json_string := JSON.stringify(current_controls, "\t")
		file.store_string(json_string)
		file.close()
		
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(SAVE_PATH)
		DirAccess.rename_absolute(temp_path, SAVE_PATH)
	else:
		push_error("InputManager: Không thể ghi file tạm: ", temp_path)

# Áp dụng cấu hình nút vào InputMap của Engine
func apply_controls() -> void:
	for action in current_controls.keys():
		var keycode: int = current_controls[action]
		
		# Xóa các event cũ của hành động
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action)
			
		# Tạo event phím bấm mới
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)

# Thay đổi phím bấm cho một hành động
func remap_action(action_name: String, new_keycode: int) -> void:
	current_controls[action_name] = new_keycode
	save_controls()
	apply_controls()

