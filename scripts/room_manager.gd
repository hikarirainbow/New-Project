extends Node

var player_instance: Node2D = null

# Function to transition to a new scene
func transition_to_room(room_scene_path: String, spawn_at_portal: String) -> void:
	var current_scene = get_tree().current_scene
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		player_instance = player
		# Remove player from current scene so it isn't deleted
		player.get_parent().remove_child(player)
	
	# Load the new scene
	get_tree().change_scene_to_file(room_scene_path)
	
	# Wait for the node_added signal to know when the new scene is added
	await get_tree().node_added
	# Wait for a frame to ensure all nodes are fully ready
	await get_tree().process_frame
	
	var new_scene = get_tree().current_scene
	if new_scene and player_instance:
		# Remove the newly instantiated player in the new scene to avoid duplicates
		var new_player = new_scene.get_node_or_null("Player")
		if new_player:
			new_player.remove_from_group("player")
			new_player.queue_free()
		
		# Add our persistent player node
		new_scene.add_child(player_instance)
		player_instance.name = "Player"
		
		# Position the player near the target portal
		var target_portal = null
		for portal in get_tree().get_nodes_in_group("portals"):
			if portal.portal_id == spawn_at_portal:
				target_portal = portal
				break
		
		if target_portal:
			player_instance.global_position = target_portal.global_position
			# Offset player horizontally to prevent immediate loop triggering
			if spawn_at_portal == "left":
				player_instance.global_position.x += 48
			elif spawn_at_portal == "right":
				player_instance.global_position.x -= 48
		else:
			# Fallback positioning
			player_instance.global_position = Vector2(160, 576)
			
		player_instance.velocity = Vector2.ZERO
		
		# Reset physics interpolation to prevent teleportation visual glitches
		player_instance.reset_physics_interpolation()
		
		# Reset camera smoothing and limits
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
		
		# Explicitly update the new scene's HUD with the persistent player
		var hud = new_scene.get_node_or_null("HUD")
		if hud and hud.has_method("setup_player"):
			hud.setup_player(player_instance)
