extends CanvasLayer

@onready var slider: HSlider = $VBoxContainer/HSlider
@onready var label: Label = $VBoxContainer/Label
@onready var map_gen: Node = get_tree().root.get_node("MainLevel/MapLayer") # Đường dẫn cứng, cần đảm bảo đúng Scene Tree

func _ready() -> void:
	if map_gen:
		slider.value = map_gen.render_distance
		label.text = "Render Distance: " + str(slider.value) + " chunks"
	else:
		label.text = "Map Generator not found!"

func _on_h_slider_value_changed(value: float) -> void:
	label.text = "Render Distance: " + str(value) + " chunks"
	if map_gen:
		map_gen.update_render_distance(value)
