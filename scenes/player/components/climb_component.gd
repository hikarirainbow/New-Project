class_name ClimbComponent
extends Node2D

const CLIMB_DURATION = 0.5

var climb_start_pos: Vector2
var climb_target_pos: Vector2
var climb_timer: float = 0.0

@onready var player = get_parent()

# Ledge check with auto-position correction using physics raycasts
func check_ledge() -> Dictionary:
	if player.is_on_floor():
		return {}
		
	var space_state = player.get_world_2d().direct_space_state
	var facing_dir = -1.0 if (player.has_node("Sprite2D") and player.get_node("Sprite2D").flip_h) else 1.0
	
	# 1. Cast horizontal ray at lower body level (Y = 16) - must hit solid tile (checks wall presence)
	var lower_start = player.global_position + Vector2(0, 16)
	var lower_end = lower_start + Vector2(facing_dir * 20, 0)
	var query_lower = PhysicsRayQueryParameters2D.create(lower_start, lower_end, 1)
	query_lower.exclude = [player.get_rid()]
	var result_lower = space_state.intersect_ray(query_lower)
	
	if result_lower.is_empty():
		return {}
		
	# 2. Cast horizontal ray at upper body level (Y = -16) - must NOT hit (checks for ledge clearance)
	var upper_start = player.global_position + Vector2(0, -16)
	var upper_end = upper_start + Vector2(facing_dir * 20, 0)
	var query_upper = PhysicsRayQueryParameters2D.create(upper_start, upper_end, 1)
	query_upper.exclude = [player.get_rid()]
	var result_upper = space_state.intersect_ray(query_upper)
	
	if not result_upper.is_empty():
		return {}
		
	# 3. Project vertical ray downwards from above the wall face to find the exact top surface Y coordinate
	var wall_x = result_lower.position.x
	var check_top_start = Vector2(wall_x + facing_dir * 4, result_lower.position.y - 24)
	var check_top_end = Vector2(wall_x + facing_dir * 4, result_lower.position.y + 24)
	var query_top = PhysicsRayQueryParameters2D.create(check_top_start, check_top_end, 1)
	query_top.exclude = [player.get_rid()]
	var result_top = space_state.intersect_ray(query_top)
	
	if result_top.is_empty():
		return {}
		
	var ledge_top_y = result_top.position.y
	
	# Compute destination position slightly offset from the tile corner
	var target_pos = Vector2(wall_x + facing_dir * 15.0, ledge_top_y - 32.0)
	
	# 4. Check if stand location has sufficient height/ceiling clearance (checks for ceiling collision)
	var query_clear = PhysicsRayQueryParameters2D.create(target_pos, target_pos + Vector2(0, -30), 1)
	query_clear.exclude = [player.get_rid()]
	var result_clear = space_state.intersect_ray(query_clear)
	if not result_clear.is_empty():
		return {}
		
	return {
		"target_position": target_pos,
		"start_position": player.global_position
	}

# Start climbing sequence
func start_climb(target_pos: Vector2) -> void:
	player.current_state = Player.State.CLIMB
	climb_start_pos = player.global_position
	climb_target_pos = target_pos
	climb_timer = 0.0
	player.velocity = Vector2.ZERO
	
	# Interrupt attacks and dashes
	if player.has_node("AttackComponent"):
		player.get_node("AttackComponent").interrupt()
	if player.has_node("DashComponent"):
		player.get_node("DashComponent").interrupt()
		
	# Temporarily disable solid tile collisions to prevent wall stuck/jitter glitches
	player.set_collision_mask_value(1, false)

# Process L-shaped LERP climbing animation (vertical rise phase, then horizontal step phase)
func process_climb(delta: float) -> void:
	climb_timer += delta
	var t = climb_timer / CLIMB_DURATION
	t = clamp(t, 0.0, 1.0)
	
	# Phase 1: Rise vertically first
	if t < 0.5:
		var ratio = t / 0.5
		var ease_ratio = sin(ratio * PI * 0.5)
		player.global_position.y = lerp(climb_start_pos.y, climb_target_pos.y, ease_ratio)
		player.global_position.x = climb_start_pos.x
		# Apply vertical stretch squash scale to indicate jumping effort
		if player.has_node("Sprite2D"):
			player.get_node("Sprite2D").scale = Vector2(0.22, 0.58)
	# Phase 2: Step forward horizontally
	else:
		var ratio = (t - 0.5) / 0.5
		var ease_ratio = sin(ratio * PI * 0.5)
		player.global_position.y = climb_target_pos.y
		player.global_position.x = lerp(climb_start_pos.x, climb_target_pos.x, ease_ratio)
		# Apply horizontal squash scale to simulate landing
		if player.has_node("Sprite2D"):
			player.get_node("Sprite2D").scale = Vector2(0.28, 0.42)
			
	if climb_timer >= CLIMB_DURATION:
		# Complete climb sequence
		player.global_position = climb_target_pos
		if player.has_node("Sprite2D"):
			player.get_node("Sprite2D").scale = Vector2(0.25, 0.5) # Restore original sprite scale
		player.set_collision_mask_value(1, true) # Re-enable solid tile collisions
		player.current_state = Player.State.MOVE

# Force interrupt climb sequence (e.g. taking damage)
func interrupt() -> void:
	if player.current_state == Player.State.CLIMB:
		player.set_collision_mask_value(1, true)
		if player.has_node("Sprite2D"):
			player.get_node("Sprite2D").scale = Vector2(0.25, 0.5)
		player.current_state = Player.State.MOVE
