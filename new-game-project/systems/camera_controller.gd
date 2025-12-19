extends Node2D

signal area_selected(rect: Rect2)

const GRID_SIZE = 64
const UNIT_SCENE = preload("res://entities/units/unit.tscn")

@export_category("Camera Settings")
@export var move_speed: float = 500.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 4.0
@export var zoom_smoothing: float = 0.1

@onready var camera: Camera2D = $Camera2D

var target_zoom: Vector2 = Vector2.ONE
var game_ui: CanvasLayer
var mouse_highlight: ColorRect

var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 1. Đăng ký phím WASD vào InputMap (Fix cứng)
	setup_input_map()
	
	# 2. Thiết lập Camera
	camera.make_current()
	target_zoom = camera.zoom
	
	# 3. Kết nối UI
	game_ui = get_parent().get_node_or_null("GameUI")
	
	# 4. Mouse Highlight
	mouse_highlight = ColorRect.new()
	mouse_highlight.name = "MouseHighlight"
	mouse_highlight.size = Vector2(GRID_SIZE, GRID_SIZE)
	mouse_highlight.color = Color(1, 1, 1, 0.3)
	mouse_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camera.add_child(mouse_highlight)

func setup_input_map() -> void:
	# Tạo action ảo cho camera
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
	
	# Zoom Smoothing
	camera.zoom = camera.zoom.lerp(target_zoom, zoom_smoothing)
	
	# Update snapped mouse position
	var snapped_pos = (get_global_mouse_position() / GRID_SIZE).floor() * GRID_SIZE
	mouse_highlight.global_position = snapped_pos
	
	# Cập nhật tọa độ
	if game_ui:
		game_ui.update_coords(position)
		
	if is_dragging:
		queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			change_zoom(zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			change_zoom(-zoom_speed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		spawn_unit_at_center()
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_start = get_global_mouse_position()
		elif is_dragging:
			is_dragging = false
			var drag_end = get_global_mouse_position()
			var rect = Rect2(drag_start, drag_end - drag_start).abs()
			area_selected.emit(rect)
			queue_redraw()

func _draw() -> void:
	if is_dragging:
		var current_pos = get_global_mouse_position()
		var rect = Rect2(to_local(drag_start), to_local(current_pos) - to_local(drag_start))
		draw_rect(rect, Color(0, 0, 1, 0.2), true)
		draw_rect(rect, Color(0, 0, 1, 1), false, 1.0)

func spawn_unit_at_center() -> void:
	var unit = UNIT_SCENE.instantiate()
	unit.global_position = camera.get_screen_center_position()
	get_parent().add_child(unit)

func handle_movement(delta: float) -> void:
	# Sử dụng Input.get_vector để di chuyển mượt mà 8 hướng
	var direction = Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
	
	# Tốc độ di chuyển tỉ lệ nghịch với Zoom
	var zoom_factor = clamp(1.0 / camera.zoom.x, 0.5, 3.0)
	var current_speed = move_speed * zoom_factor
	
	position += direction * current_speed * delta

func change_zoom(amount: float) -> void:
	target_zoom += Vector2(amount, amount)
	target_zoom.x = clamp(target_zoom.x, min_zoom, max_zoom)
	target_zoom.y = clamp(target_zoom.y, min_zoom, max_zoom)
