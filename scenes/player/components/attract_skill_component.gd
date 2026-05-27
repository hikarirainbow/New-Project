class_name AttractSkillComponent
extends Node2D

@export var cooldown_duration: float = 3.0
@export var cone_range: float = 200.0
@export var cone_angle_deg: float = 30.0

var cooldown_timer: float = 0.0
var cone_alpha: float = 0.0

@onready var player: Player = get_parent() as Player

func _ready() -> void:
	# Z-index to render above background but maybe below/above sprite
	z_index = 5

func _physics_process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		
	# Redraw the cone while alpha is active
	if cone_alpha > 0.0:
		queue_redraw()

	if Input.is_action_just_pressed("skill_attract") and cooldown_timer <= 0.0:
		if player.current_state == Player.State.MOVE:
			cast_skill()

func cast_skill() -> void:
	cooldown_timer = cooldown_duration
	
	# Trigger vector drawing animation
	cone_alpha = 0.4
	var tween = player.create_tween().set_ignore_time_scale(true)
	tween.tween_property(self, "cone_alpha", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Scan for enemies in cone
	var enemies = get_tree().get_nodes_in_group("enemies")
	var is_facing_left = player.get_node("Sprite2D").flip_h if player.has_node("Sprite2D") else false
	var forward = Vector2.LEFT if is_facing_left else Vector2.RIGHT
	var half_angle_rad = deg_to_rad(cone_angle_deg) / 2.0
	
	print("[ATTRACT] Cast! Scanning in range: ", cone_range, " | arc: ", cone_angle_deg)
	
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("is_alive") and enemy.is_alive():
			var diff = enemy.global_position - player.global_position
			var dist = diff.length()
			if dist <= cone_range:
				# Use angle_to to compute signed angle difference
				var angle_diff = abs(forward.angle_to(diff))
				if angle_diff <= half_angle_rad:
					_apply_attract_effect(enemy)

func _apply_attract_effect(enemy: Node) -> void:
	var existing = enemy.get_node_or_null("AttractEffectComponent")
	if existing:
		existing.refresh()
		print("[ATTRACT] Refreshed duration on: ", enemy.name)
	else:
		var effect_script = load("res://scenes/enemies/components/attract_effect_component.gd")
		var effect = Node.new()
		effect.name = "AttractEffectComponent"
		effect.set_script(effect_script)
		enemy.add_child(effect)
		print("[ATTRACT] Applied to enemy: ", enemy.name)

func _draw() -> void:
	if cone_alpha > 0.0:
		var points = get_sector_points(cone_range, cone_angle_deg)
		# Vivid glassmorphism neon color
		var fill_color = Color(1.0, 0.3, 0.7, cone_alpha * 0.7)
		var line_color = Color(1.0, 0.5, 0.8, cone_alpha)
		
		# Draw the polygon sector
		draw_polygon(points, [fill_color])
		
		# Draw border outline for higher visual quality
		for i in range(1, points.size() - 1):
			draw_line(points[i], points[i+1], line_color, 1.5, true)
		draw_line(points[0], points[1], line_color, 1.5, true)
		draw_line(points[0], points[points.size() - 1], line_color, 1.5, true)

func get_sector_points(radius: float, angle_deg: float, segments: int = 16) -> PackedVector2Array:
	var points = PackedVector2Array()
	points.append(Vector2.ZERO) # Origin center
	
	var half_angle = deg_to_rad(angle_deg) / 2.0
	var is_facing_left = player.get_node("Sprite2D").flip_h if player.has_node("Sprite2D") else false
	var base_angle = PI if is_facing_left else 0.0
	
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var a = base_angle + lerp(-half_angle, half_angle, t)
		points.append(Vector2(cos(a), sin(a)) * radius)
		
	return points
