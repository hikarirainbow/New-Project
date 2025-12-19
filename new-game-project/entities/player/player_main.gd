extends Node2D
class_name PlayerMain

@export_category("Camera Settings")
@export var move_speed: float = 500.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 4.0
@export var zoom_smoothing: float = 0.1

@onready var camera: Camera2D = $Camera2D

var target_zoom: Vector2 = Vector2.ONE
var game_ui: CanvasLayer
var game_manager: GameManager

# --- SELECTION VARIABLES ---
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_end: Vector2 = Vector2.ZERO
var selected_units: Array[Node2D] = []
var is_dig_mode: bool = false # Biến mới: Chế độ đào

func _ready() -> void:
	setup_input_map()
	camera.make_current()
	target_zoom = camera.zoom
	game_ui = get_tree().root.find_child("GameUI", true, false)
	game_manager = get_tree().get_first_node_in_group("game_manager")
	
	# Kết nối tín hiệu từ UI Dig Button
	if game_ui:
		game_ui.dig_mode_toggled.connect(_on_dig_mode_toggled)

func _on_dig_mode_toggled(active: bool) -> void:
	is_dig_mode = active
	print("Dig Mode: ", is_dig_mode)
	# Clear selection nếu chuyển chế độ
	selected_units.clear()

func setup_input_map() -> void:
	add_camera_action("cam_left", KEY_A)
	add_camera_action("cam_right", KEY_D)
	add_camera_action("cam_up", KEY_W)
	add_camera_action("cam_down", KEY_S)

func add_camera_action(action_name: String, key_code: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var ev = InputEventKey.new()
		ev.physical_keycode = key_code
		InputMap.action_add_event(action_name, ev)

func _process(delta: float) -> void:
	handle_movement(delta)
	camera.zoom = camera.zoom.lerp(target_zoom, zoom_smoothing)
	if game_ui and game_ui.has_method("update_coords"):
		game_ui.update_coords(position)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
			change_zoom(zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			change_zoom(-zoom_speed)
		
		# --- CHUỘT TRÁI: SELECT / DIG ---
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				is_dragging = true
				drag_start = get_global_mouse_position()
			else:
				if is_dragging:
					is_dragging = false
					drag_end = get_global_mouse_position()
					
					if is_dig_mode:
						mark_dig_area()
					else:
						select_units_in_area()
		
		# --- CHUỘT PHẢI: MOVE COMMAND ---
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			issue_move_command(get_global_mouse_position())

	elif event is InputEventMouseMotion and is_dragging:
		drag_end = get_global_mouse_position()

func _draw() -> void:
	if is_dragging:
		var local_start = to_local(drag_start)
		var local_end = to_local(drag_end)
		var rect = Rect2(local_start, local_end - local_start)
		
		if is_dig_mode:
			# Màu Đỏ/Vàng cho Dig
			draw_rect(rect, Color(1.0, 0.4, 0.2, 0.3), true)
			draw_rect(rect, Color(1.0, 0.4, 0.2, 0.8), false, 2.0)
		else:
			# Màu Xanh cho Selection
			draw_rect(rect, Color(0.2, 0.4, 1.0, 0.3), true)
			draw_rect(rect, Color(0.2, 0.4, 1.0, 0.8), false, 2.0)

func select_units_in_area() -> void:
	selected_units.clear()
	var rect = Rect2(drag_start, drag_end - drag_start).abs()
	var all_units = get_tree().get_nodes_in_group("unit")
	for unit in all_units:
		if unit is Node2D:
			if rect.has_point(unit.global_position):
				selected_units.append(unit)
				unit.modulate = Color(0.5, 1.0, 0.5) 
			else:
				unit.modulate = Color.WHITE
	print("Selected: ", selected_units.size())

func mark_dig_area() -> void:
	if not game_manager: return
	
	var map = get_tree().get_first_node_in_group("terrain") as TileMapLayer
	if not map: return
	
	var rect = Rect2(drag_start, drag_end - drag_start).abs()
	
	# Duyệt qua các tile trong vùng rect
	# Để tối ưu, convert rect start/end sang map coords
	var start_coord = map.local_to_map(map.to_local(rect.position))
	var end_coord = map.local_to_map(map.to_local(rect.end))
	
	for x in range(start_coord.x, end_coord.x + 1):
		for y in range(start_coord.y, end_coord.y + 1):
			var pos = Vector2i(x, y)
			# Nếu là ô có gạch (Solid) -> Thêm task
			if map.get_cell_source_id(pos) != -1:
				game_manager.add_dig_task(pos)

func issue_move_command(target_pos: Vector2) -> void:
	if selected_units.is_empty(): return
	var valid_pos = find_ground_below(target_pos)
	print("Ra lệnh di chuyển tới: ", valid_pos)
	for unit in selected_units:
		if unit.has_method("set_path"):
			# Gọi API pathfinding của GameManager
			if game_manager:
				var path = game_manager.get_path_cells(unit.global_position, valid_pos)
				unit.set_path(path)

func find_ground_below(pos: Vector2) -> Vector2:
	var map = get_tree().get_first_node_in_group("terrain") as TileMapLayer
	if not map: return pos
	var tile_pos = map.local_to_map(map.to_local(pos))
	for i in range(50):
		var check_pos = tile_pos + Vector2i(0, i)
		if map.get_cell_source_id(check_pos) != -1:
			return map.to_global(map.map_to_local(check_pos + Vector2i(0, -1)))
	return pos

func handle_movement(delta: float) -> void:
	var direction = Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
	var zoom_factor = clamp(1.0 / camera.zoom.x, 0.5, 3.0)
	var current_speed = move_speed * zoom_factor
	position += direction * current_speed * delta

func change_zoom(amount: float) -> void:
	target_zoom += Vector2(amount, amount)
	target_zoom.x = clamp(target_zoom.x, min_zoom, max_zoom)
	target_zoom.y = clamp(target_zoom.y, min_zoom, max_zoom)
