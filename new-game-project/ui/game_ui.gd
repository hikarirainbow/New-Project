extends CanvasLayer

signal spawn_requested
signal dig_mode_toggled(is_active: bool)

@onready var btn_spawn: Button = $PanelContainer/HBoxContainer/BtnSpawn
@onready var btn_dig: Button = $PanelContainer/HBoxContainer/BtnDig
@onready var coords_label: Label = $CoordsLabel

func _ready() -> void:
	# Tự động tắt Focus cho mọi nút để tránh chiếm quyền điều khiển Camera
	disable_focus_recursive(self)

func disable_focus_recursive(node: Node) -> void:
	if node is Control:
		node.focus_mode = Control.FOCUS_NONE
	
	for child in node.get_children():
		disable_focus_recursive(child)

func _on_btn_spawn_pressed() -> void:
	spawn_requested.emit()

func _on_btn_dig_toggled(toggled_on: bool) -> void:
	dig_mode_toggled.emit(toggled_on)
	if toggled_on:
		btn_dig.modulate = Color(0.5, 1.0, 0.5)
	else:
		btn_dig.modulate = Color.WHITE

func update_coords(pos: Vector2) -> void:
	coords_label.text = "Cam: (%d, %d)" % [int(pos.x), int(pos.y)]
