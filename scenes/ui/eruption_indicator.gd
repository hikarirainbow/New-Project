# res://scenes/ui/eruption_indicator.gd
extends Control

var title_label: Label = null
var value_label: Label = null
var player_ref: Player = null

# Dynamic Opacity & Alert Configuration
var target_opacity: float = 0.1
var show_timer: float = 0.0
var prev_eruption_progress: float = -1.0

func _ready() -> void:
	# Configure anchors for bottom-left positioning
	anchor_top = 1.0
	anchor_bottom = 1.0
	anchor_left = 0.0
	anchor_right = 0.0
	
	# 100x100 pixels size, shifted right by 20px, 20px margin from bottom
	offset_left = 20.0
	offset_top = -120.0
	offset_right = 120.0
	offset_bottom = -20.0
	
	custom_minimum_size = Vector2(100, 100)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Set pivot to center for nice scale pulsing animations
	pivot_offset = Vector2(50, 50)
	
	# Start with low opacity
	modulate.a = 0.1
	
	# Set up VBoxContainer for centering labels
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", -2)
	add_child(vbox)
	
	# Title Label (Small "ERUPTION")
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "ERUPTION"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 8)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.078, 0.576)) # Hot Pink
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title_label.add_theme_constant_override("outline_size", 3)
	vbox.add_child(title_label)
	
	# Value Label (Larger "%")
	value_label = Label.new()
	value_label.name = "ValueLabel"
	value_label.text = "0%"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	value_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	value_label.add_theme_constant_override("outline_size", 4)
	vbox.add_child(value_label)
	
	# Fetch player reference
	await get_tree().process_frame
	player_ref = get_tree().get_first_node_in_group("player") as Player

func _process(delta: float) -> void:
	queue_redraw()
	
	if player_ref and player_ref.corruption_component:
		var max_sanity_val = player_ref.corruption_component.max_sanity
		# Eruption progress represents how much max sanity has shrunk from 100 to 50
		var eruption_progress = (100.0 - max_sanity_val) / 50.0 * 100.0
		value_label.text = "%d%%" % int(round(eruption_progress))
		
		# If Eruption progress changed, trigger 3-second visibility window and pulse scale
		if prev_eruption_progress >= 0.0 and abs(eruption_progress - prev_eruption_progress) > 0.01:
			show_timer = 3.0
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			
		prev_eruption_progress = eruption_progress
		
		# H-scene active check
		var h_scene_active = player_ref._h_scene_active
		
		# If H-scene is active, flash red/pink title alert
		if h_scene_active:
			title_label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))
		else:
			title_label.add_theme_color_override("font_color", Color(1.0, 0.078, 0.576))
			
		# Update show timer
		if show_timer > 0.0:
			show_timer -= delta
			
		# Determine target opacity
		if h_scene_active or show_timer > 0.0:
			target_opacity = 1.0
		else:
			target_opacity = 0.1
	else:
		value_label.text = "0%"
		target_opacity = 0.1
		
	# Smoothly interpolate opacity toward target
	modulate.a = move_toward(modulate.a, target_opacity, 2.5 * delta)

func _draw() -> void:
	var center = Vector2(50.0, 50.0)
	var time = Time.get_ticks_msec() / 1000.0
	
	var is_erupting = false
	var pulse_speed = 2.0
	if player_ref and player_ref._h_scene_active:
		is_erupting = true
		pulse_speed = 8.0 # Pulse rapidly during H-scene grabbed state
		
	var pulse = 0.5 + 0.5 * sin(time * pulse_speed)
	
	# 1. Draw outer black outline (radius 50.0)
	draw_circle(center, 50.0, Color(0.0, 0.0, 0.0, 1.0))
	
	# 2. Draw pink border (radius 49.0, leaves a 1px outer black outline)
	var pink_color = Color(1.0, 0.078, 0.576).lerp(Color(1.0, 0.4, 0.7), pulse if not is_erupting else pulse * 0.5)
	if is_erupting:
		pink_color = pink_color.lerp(Color(1.0, 0.0, 0.0), pulse) # Pulse to red when erupting
	draw_circle(center, 49.0, pink_color)
	
	# 3. Draw inner purple-black background (radius 47.0, leaves a 2px pink border width)
	var purple_black = Color(0.08, 0.02, 0.12, 1.0)
	draw_circle(center, 47.0, purple_black)
	
	# 4. Draw dynamic inner glowing core reflecting current eruption progress
	if player_ref and player_ref.corruption_component:
		var max_sanity_val = player_ref.corruption_component.max_sanity
		var ratio = (100.0 - max_sanity_val) / 50.0
		if ratio > 0.01:
			var core_radius = 45.0 * ratio
			var core_color = Color(1.0, 0.078, 0.576, 0.15 + 0.08 * sin(time * pulse_speed))
			if is_erupting:
				core_color = Color(1.0, 0.0, 0.0, 0.25 + 0.15 * sin(time * pulse_speed))
			draw_circle(center, core_radius, core_color)
