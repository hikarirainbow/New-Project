extends Node

var player_instance: Node2D = null
var is_transitioning: bool = false
var persisted_corpses: Dictionary = {}

# Function to transition to a new scene
func transition_to_room(room_scene_path: String, spawn_at_portal: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	# Save state of current room before switching
	var current_scene = get_tree().current_scene
	if current_scene:
		save_room_state(current_scene.scene_file_path, current_scene)
	
	# 1. Fade out the old scene's HUD
	if current_scene:
		var old_hud = current_scene.get_node_or_null("HUD")
		if old_hud and old_hud.has_method("fade_to_black"):
			await old_hud.fade_to_black(0.15).finished
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_instance = player
		# Remove player from current scene so it isn't deleted
		player.get_parent().remove_child(player)
	
	# Instantiate the new scene (Room B)
	var next_scene = load(room_scene_path).instantiate()
	
	# Remove the default Player node in the new scene immediately so it never enters the tree or renders
	var new_player = next_scene.get_node_or_null("Player")
	if new_player:
		next_scene.remove_child(new_player)
		new_player.queue_free()
		
	# Find the new HUD and set it to fully black immediately to prevent transition pop/flash
	var new_hud = next_scene.get_node_or_null("HUD")
	if new_hud:
		var screen_fade = new_hud.get_node_or_null("Control/ScreenFade")
		if screen_fade:
			screen_fade.color = Color(0, 0, 0, 1)
	
	# Determine spawn position based on target portal (hardcoded offsets to prevent dependency on uninitialized nodes)
	var spawn_pos = Vector2(160, 576) # Fallback
	if spawn_at_portal == "left":
		spawn_pos = Vector2(64, 576) # Left portal (16, 576) + offset (48)
	elif spawn_at_portal == "right":
		spawn_pos = Vector2(1856, 576) # Right portal (1904, 576) - offset (48)
		
	# Position the player and clear velocity before adding to the tree
	player_instance.position = spawn_pos
	player_instance.velocity = Vector2.ZERO
	
	# Add the persistent player node to the new scene
	next_scene.add_child(player_instance)
	player_instance.name = "Player"
	
	# Replace current scene in SceneTree
	var root = get_tree().root
	var old_scene = get_tree().current_scene
	if old_scene:
		root.remove_child(old_scene)
		old_scene.queue_free()
		
	root.add_child(next_scene)
	get_tree().current_scene = next_scene
	
	# Reset camera and physics interpolation
	player_instance.reset_physics_interpolation()
	
	var cam = player_instance.get_node_or_null("Camera2D")
	if cam:
		cam.make_current() # Force this camera to be active in the new scene
		cam.position_smoothing_enabled = false
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = 1920 # 60 * 32
		cam.limit_bottom = 640 # 20 * 32
		cam.global_position = player_instance.global_position
		cam.reset_physics_interpolation()
		cam.force_update_scroll()
		cam.position_smoothing_enabled = true
		cam.reset_smoothing()
		
	# Setup new HUD and trigger fade in
	if new_hud:
		if new_hud.has_method("setup_player"):
			new_hud.setup_player(player_instance)
		if new_hud.has_method("fade_from_black"):
			new_hud.fade_from_black(0.15)
		
	is_transitioning = false

func save_room_state(room_path: String, room_node: Node) -> void:
	var corpses = []
	for enemy in room_node.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and not enemy.is_alive():
			corpses.append(enemy.global_position)
			
	# Limit maximum saved corpses to 15 per room to prevent rendering/physics lag
	if corpses.size() > 15:
		corpses = corpses.slice(corpses.size() - 15)
		
	persisted_corpses[room_path] = corpses
	print("[ROOM] Saved ", corpses.size(), " corpses for: ", room_path)

func clear_corpses() -> void:
	persisted_corpses.clear()
	print("[ROOM] All persisted corpses cleared.")
