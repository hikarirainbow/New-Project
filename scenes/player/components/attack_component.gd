class_name AttackComponent
extends Node2D

const ATTACK_DURATION = 0.15
const COMBO_RESET_DELAY = 0.5

var attack_timer = 0.0
var combo_reset_timer = 0.0
var combo_index = 0
var current_combo_index = 0

var bodies_hit_this_attack: Array[Node] = []
var attack_area_collision: CollisionShape2D = null
var attack_shape_2: CollisionShape2D = null

@onready var player: CharacterBody2D = get_parent()

func _ready() -> void:
	var attack_area = player.get_node_or_null("AttackArea")
	if attack_area:
		attack_area.body_entered.connect(_on_attack_body_entered)
		attack_area_collision = attack_area.get_node_or_null("CollisionShape2D")
		
		# Dynamically initialize secondary collision shape for 2nd hit combo variation
		attack_shape_2 = CollisionShape2D.new()
		var rect2 = RectangleShape2D.new()
		attack_shape_2.shape = rect2
		attack_shape_2.disabled = true
		attack_area.add_child(attack_shape_2)

func _physics_process(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta
		
		# Manual query for overlapping bodies to handle static tiles and overlap quirks
		var attack_area = player.get_node_or_null("AttackArea")
		if attack_area:
			for body in attack_area.get_overlapping_bodies():
				_on_attack_body_entered(body)
				
		queue_redraw()
		if attack_timer <= 0.0:
			end_attack()
			
	if combo_reset_timer > 0.0 and attack_timer <= 0.0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0.0:
			combo_index = 0 # Reset to 1st attack in combo chain

func is_attacking() -> bool:
	return attack_timer > 0.0

func can_attack() -> bool:
	return attack_timer <= 0.0

func start_attack() -> void:
	current_combo_index = combo_index
	
	var duration = ATTACK_DURATION
	if player and player.skill_component and player.skill_component.is_skill_unlocked("B"):
		duration = 0.10 # Faster attack duration (0.10s instead of 0.15s)
		
	attack_timer = duration
	combo_reset_timer = 0.0
	bodies_hit_this_attack.clear()
	
	var is_facing_left = player.get_node("Sprite2D").flip_h if player.has_node("Sprite2D") else false
	
	if attack_area_collision and attack_area_collision.shape:
		attack_area_collision.disabled = false
		
		match current_combo_index:
			0:
				attack_area_collision.shape.size = Vector2(40.0, 68.0)
				attack_area_collision.position.x = -38.0 if is_facing_left else 38.0
				attack_area_collision.position.y = 9.0
				if attack_shape_2:
					attack_shape_2.disabled = true
			1:
				attack_area_collision.shape.size = Vector2(40.0, 68.0)
				attack_area_collision.position.x = -38.0 if is_facing_left else 38.0
				attack_area_collision.position.y = 9.0
				if attack_shape_2 and attack_shape_2.shape:
					attack_shape_2.disabled = false
					attack_shape_2.shape.size = Vector2(70.0, 40.0)
					attack_shape_2.position.x = 0.0
					attack_shape_2.position.y = -52.0
					attack_shape_2.shape = attack_shape_2.shape # Force shape update
			2:
				attack_area_collision.shape.size = Vector2(50.0, 48.0)
				attack_area_collision.position.x = -43.0 if is_facing_left else 43.0
				attack_area_collision.position.y = 9.0
				if attack_shape_2:
					attack_shape_2.disabled = true
		
		# Force physics cache refresh on shape updates
		attack_area_collision.shape = attack_area_collision.shape
	queue_redraw()

func end_attack() -> void:
	if attack_area_collision:
		attack_area_collision.disabled = true
	if attack_shape_2:
		attack_shape_2.disabled = true
		
	combo_index = (current_combo_index + 1) % 3
	
	var reset_delay = COMBO_RESET_DELAY
	if player and player.skill_component and player.skill_component.is_skill_unlocked("B"):
		reset_delay = 0.35 # Quicker combo chain window reset
		
	combo_reset_timer = reset_delay
	queue_redraw()

func interrupt() -> void:
	if attack_timer > 0.0:
		end_attack()
		attack_timer = 0.0

func _on_attack_body_entered(body: Node2D) -> void:
	# Determine slash direction based on player facing direction
	var is_facing_left = player.get_node("Sprite2D").flip_h if player.has_node("Sprite2D") else false
	var slash_dir = -1.0 if is_facing_left else 1.0

	print("[ATTACK DEBUG] Overlapped body: ", body.name, " (class: ", body.get_class(), ", layer: ", body.collision_layer, ")")

	# Case A: Hit an enemy or destructible object
	if body.has_method("take_damage") and not bodies_hit_this_attack.has(body):
		bodies_hit_this_attack.append(body)
		var base_damage = 20
		if player and player.has_node("CorruptionComponent"):
			var corruption_node = player.get_node("CorruptionComponent")
			base_damage = int(round(base_damage * corruption_node.get_attack_multiplier()))
			
		# Apply Skill A: +50% Base Damage multiplier
		if player and player.skill_component and player.skill_component.is_skill_unlocked("A"):
			base_damage = int(round(base_damage * 1.5))
			
		# Apply Skill C: Critical Strike (20% chance to deal 2x damage)
		if player and player.skill_component and player.skill_component.is_skill_unlocked("C"):
			if randf() <= 0.20:
				base_damage *= 2
				print("[COMBAT] CRITICAL! Damage doubled to: ", base_damage)
				
		body.take_damage(base_damage, player.global_position)
		
		# Melee impact effects: hit stop, slash-opposite camera shake, and recoil
		if player.has_method("trigger_hit_stop"):
			player.trigger_hit_stop(0.08, 0.05)
		if player.has_method("shake_camera"):
			player.shake_camera(slash_dir, 8.0, 0.15)
		if player.has_method("apply_melee_recoil"):
			player.apply_melee_recoil(slash_dir, 140.0)

	# Case B: Hit a tile / wall (Environment Layer 1)
	elif not body.has_method("take_damage") and not bodies_hit_this_attack.has(body):
		bodies_hit_this_attack.append(body)
		
		# Tile impact feel
		if player.has_method("trigger_hit_stop"):
			player.trigger_hit_stop(0.05, 0.05)
		if player.has_method("shake_camera"):
			player.shake_camera(slash_dir, 5.0, 0.12)
		if player.has_method("apply_melee_recoil"):
			player.apply_melee_recoil(slash_dir, 160.0)

func _draw() -> void:
	if attack_timer > 0.0:
		var is_facing_left = player.get_node("Sprite2D").flip_h if player.has_node("Sprite2D") else false
		match current_combo_index:
			0:
				var x_pos = -58.0 if is_facing_left else 18.0
				draw_rect(Rect2(x_pos, -25.0, 40.0, 68.0), Color(0.15, 0.15, 0.85, 0.6))
			1:
				var x_pos = -58.0 if is_facing_left else 18.0
				draw_rect(Rect2(x_pos, -25.0, 40.0, 68.0), Color(0.15, 0.85, 0.15, 0.6))
				draw_rect(Rect2(-35.0, -72.0, 70.0, 40.0), Color(0.15, 0.85, 0.15, 0.6))
			2:
				var x_pos = -68.0 if is_facing_left else 18.0
				draw_rect(Rect2(x_pos, -15.0, 50.0, 48.0), Color(0.85, 0.15, 0.15, 0.6))
