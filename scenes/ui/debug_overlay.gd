# res://scenes/ui/debug_overlay.gd
extends Control

var label: Label = null
var active: bool = false
var update_timer: float = 0.0

func _ready() -> void:
	# Configure anchors for top-right positioning
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	
	# Size 250x130px, 20px margin from top-right corner
	offset_left = -270.0
	offset_top = 20.0
	offset_right = -20.0
	offset_bottom = 150.0
	
	custom_minimum_size = Vector2(250, 130)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false # Invisible by default
	
	# Create Panel for dark glassmorphic background
	var panel = Panel.new()
	panel.name = "BackgroundPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.03, 0.08, 0.8) # Semi-transparent dark purple-black
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.2, 0.8, 1.0, 0.6) # Cyan neon border
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	# Create MarginContainer for text padding
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	
	# Create Label for debug text
	label = Label.new()
	label.name = "DebugLabel"
	label.text = "Initializing..."
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 3)
	margin.add_child(label)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_debug"):
		active = not active
		visible = active
		if active:
			_update_debug_text()
		print("[DEBUG] Toggle Debug Overlay: ", active)

func _process(delta: float) -> void:
	if not active:
		return
		
	update_timer += delta
	if update_timer >= 0.15: # Update text 6 times a second for readability
		update_timer = 0.0
		_update_debug_text()

func _update_debug_text() -> void:
	var fps = Engine.get_frames_per_second()
	
	# Count entities (Player, Enemies)
	var players = get_tree().get_nodes_in_group("player").size()
	var enemies = get_tree().get_nodes_in_group("enemies").size()
	var corpses = get_tree().get_nodes_in_group("player_corpse").size()
	var total_entities = players + enemies + corpses
	
	# Count Sprite2D and AnimatedSprite2D nodes in the active level scene tree
	var sprites_count = 0
	var current_scene = get_tree().current_scene
	if current_scene:
		sprites_count = _count_sprites_recursive(current_scene)
	
	# Get performance metrics
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	
	# Formulate debug string
	var txt = ""
	txt += "SYSTEM MONITOR (F4)\n"
	txt += "-------------------------\n"
	txt += "FPS: %d\n" % fps
	txt += "Entities Loaded: %d\n" % total_entities
	txt += "  ├─ Player: %d\n" % players
	txt += "  ├─ Enemies: %d\n" % enemies
	txt += "  └─ Corpses: %d\n" % corpses
	txt += "Sprites Loaded: %d\n" % sprites_count
	txt += "Draw Calls: %d\n" % draw_calls
	
	label.text = txt

func _count_sprites_recursive(node: Node) -> int:
	var count = 0
	if node is Sprite2D or node is AnimatedSprite2D:
		count += 1
	for child in node.get_children():
		count += _count_sprites_recursive(child)
	return count
