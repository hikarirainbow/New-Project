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
	attack_timer = ATTACK_DURATION
	combo_reset_timer = 0.0
	bodies_hit_this_attack.clear()
	
	var is_facing_left = player.get_node("Sprite2D").flip_h if player.has_node("Sprite2D") else false
	
	if attack_area_collision and attack_area_collision.shape:
		attack_area_collision.disabled = false
		
		match current_combo_index:
			0:
				attack_area_collision.shape.size = Vector2(40.0, 50.0)
				attack_area_collision.position.x = -36.0 if is_facing_left else 36.0
				attack_area_collision.position.y = 0.0
				if attack_shape_2:
					attack_shape_2.disabled = true
			1:
				attack_area_collision.shape.size = Vector2(40.0, 50.0)
				attack_area_collision.position.x = -36.0 if is_facing_left else 36.0
				attack_area_collision.position.y = 0.0
				if attack_shape_2 and attack_shape_2.shape:
					attack_shape_2.disabled = false
					attack_shape_2.shape.size = Vector2(70.0, 40.0)
					attack_shape_2.position.x = 0.0
					attack_shape_2.position.y = -52.0
			2:
				attack_area_collision.shape.size = Vector2(50.0, 30.0)
				attack_area_collision.position.x = -41.0 if is_facing_left else 41.0
				attack_area_collision.position.y = 0.0
				if attack_shape_2:
					attack_shape_2.disabled = true
	queue_redraw()

func end_attack() -> void:
	if attack_area_collision:
		attack_area_collision.disabled = true
	if attack_shape_2:
		attack_shape_2.disabled = true
		
	combo_index = (current_combo_index + 1) % 3
	combo_reset_timer = COMBO_RESET_DELAY
	queue_redraw()

func interrupt() -> void:
	if attack_timer > 0.0:
		end_attack()
		attack_timer = 0.0

func _on_attack_body_entered(body: Node2D) -> void:
	# Determine slash direction based on player facing direction
	var is_facing_left = player.get_node("Sprite2D").flip_h if player.has_node("Sprite2D") else false
	var slash_dir = -1.0 if is_facing_left else 1.0

	# Case A: Hit an enemy or destructible object
	if body.has_method("take_damage") and not bodies_hit_this_attack.has(body):
		bodies_hit_this_attack.append(body)
		var base_damage = 20
		if player and player.has_node("CorruptionComponent"):
			var corruption_node = player.get_node("CorruptionComponent")
			base_damage = int(round(base_damage * corruption_node.get_attack_multiplier()))
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
				var x_pos = -56.0 if is_facing_left else 16.0
				draw_rect(Rect2(x_pos, -25.0, 40.0, 50.0), Color(0.15, 0.15, 0.85, 0.6))
			1:
				var x_pos = -56.0 if is_facing_left else 16.0
				draw_rect(Rect2(x_pos, -25.0, 40.0, 50.0), Color(0.15, 0.85, 0.15, 0.6))
				draw_rect(Rect2(-35.0, -52.0, 70.0, 40.0), Color(0.15, 0.85, 0.15, 0.6))
			2:
				var x_pos = -66.0 if is_facing_left else 16.0
				draw_rect(Rect2(x_pos, -15.0, 50.0, 30.0), Color(0.85, 0.15, 0.15, 0.6))
