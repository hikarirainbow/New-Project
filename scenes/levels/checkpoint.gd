extends Area2D

var activated: bool = false
var is_player_near: bool = false
var pulse_time: float = 0.0

var prompt_label: Label = null
var point_light: PointLight2D = null

func _ready() -> void:
	# Set layers
	collision_layer = 0
	collision_mask = 2 # Detect Player (Layer 2)
	
	# Add collision shape
	var col_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 48.0
	col_shape.shape = circle
	add_child(col_shape)
	
	# Setup floating prompt label
	prompt_label = Label.new()
	prompt_label.text = "[E] REST & SKILLS"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Micro styling
	prompt_label.add_theme_font_size_override("font_size", 10)
	prompt_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	prompt_label.position = Vector2(-60, -45)
	prompt_label.custom_minimum_size = Vector2(120, 20)
	prompt_label.visible = false
	add_child(prompt_label)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Initialize PointLight2D
	_setup_light()

func _setup_light() -> void:
	point_light = PointLight2D.new()
	point_light.name = "CheckpointLight"
	point_light.enabled = true
	point_light.texture_scale = 1.5
	point_light.energy = 0.5
	
	# Radial gradient texture
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.6, 0.2, 1.0)) # Inactive warm glow
	gradient.set_color(1, Color(1.0, 0.6, 0.2, 0.0))
	
	var grad_tex = GradientTexture2D.new()
	grad_tex.gradient = gradient
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(1.0, 0.5)
	grad_tex.width = 128
	grad_tex.height = 128
	
	point_light.texture = grad_tex
	point_light.range_item_cull_mask = 1 # Light environment Layer 1
	add_child(point_light)

func _physics_process(delta: float) -> void:
	pulse_time += delta
	queue_redraw()
	
	# Animate light energy slightly
	if point_light:
		var base_energy = 1.0 if activated else 0.5
		point_light.energy = base_energy + sin(pulse_time * 4.0) * 0.1
		
	# Check for interaction
	if is_player_near and Input.is_action_just_pressed("interact"):
		var player = get_overlapping_bodies()[0] if get_overlapping_bodies().size() > 0 else null
		if player and player.is_in_group("player"):
			_interact(player)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_near = true
		prompt_label.visible = true
		body.is_at_checkpoint = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_near = false
		prompt_label.visible = false
		body.is_at_checkpoint = false

func _interact(player: Node2D) -> void:
	# Refill health and sanity
	player.current_health = player.max_health
	player.emit_signal("health_changed", player.current_health)
	
	if player.corruption_component:
		player.corruption_component.add_sanity(100.0) # Full sanity refill
		
	player.spawn_point = global_position
	
	# Clear persisted corpses in RoomManager
	if get_tree().root.has_node("RoomManager"):
		var room_manager = get_tree().root.get_node("RoomManager")
		if room_manager.has_method("clear_corpses"):
			room_manager.clear_corpses()
			
	# Delete active corpse nodes in the current room
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.has_method("is_alive") and not enemy.is_alive():
			enemy.queue_free()
	
	# Activate checkpoint
	if not activated:
		activated = true
		# Change light color to cyan
		if point_light and point_light.texture:
			var gradient = point_light.texture.gradient
			gradient.set_color(0, Color(0.2, 0.8, 1.0, 1.0)) # Cyan glow
			gradient.set_color(1, Color(0.2, 0.8, 1.0, 0.0))
		print("[CHECKPOINT] Activated and saved spawn point at: ", global_position)
		
	# Open inventory and switch to Skill Tree tab (tab 2)
	var inventory = get_tree().current_scene.get_node_or_null("Inventory")
	if inventory:
		if not inventory.is_open:
			inventory.toggle_inventory()
		inventory.switch_tab(2)

func _draw() -> void:
	# Draw base stone pedestal
	draw_rect(Rect2(-12, 10, 24, 6), Color(0.25, 0.25, 0.28))
	draw_rect(Rect2(-8, 4, 16, 6), Color(0.3, 0.3, 0.35))
	
	# Draw crystal shape
	var pulse = sin(pulse_time * 3.0) * 2.0
	var top_y = -12.0 + pulse
	var bot_y = 4.0
	
	var points = PackedVector2Array([
		Vector2(0, top_y),     # Top tip
		Vector2(6, (top_y + bot_y)/2.0), # Right corner
		Vector2(0, bot_y),     # Bottom tip
		Vector2(-6, (top_y + bot_y)/2.0) # Left corner
	])
	
	var color = Color(0.2, 0.8, 1.0, 0.9) if activated else Color(1.0, 0.6, 0.2, 0.8)
	draw_polygon(points, [color])
	# White highlight line in the center of the crystal
	draw_line(Vector2(0, top_y + 2), Vector2(0, bot_y - 2), Color(1.0, 1.0, 1.0, 0.7), 1.0)
