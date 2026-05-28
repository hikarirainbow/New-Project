class_name HSceneComponent
extends Node

signal h_scene_triggered(enemy_node: Node2D)
signal h_scene_tick(new_max_sanity: float)

# Configs
@export var qte_indicator_offset: Vector2 = Vector2(0, -82)
@export var qte_decay_rate: float = 22.5
@export var qte_trigger_range_x: float = 35.0
@export var qte_trigger_range_y: float = 25.0
@export var qte_mash_gain: float = 10.0
@export var qte_upgraded_mash_gain: float = 15.0
@export var qte_escape_invincibility_duration: float = 0.5
@export var qte_target: float = 100.0

# H-scene / QTE variables
var is_active: bool = false
var h_scene_timer: float = 0.0
var h_scene_direction: float = 1.0
var h_scene_cooldown: float = 0.0
var qte_progress: float = 0.0
var last_qte_key: String = ""

# References
var qte_attacker: Node2D = null
var rape_target_enemy: Node2D = null
var rape_timer: float = 0.0

@onready var player: Player = get_parent() as Player

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
		
	if h_scene_cooldown > 0.0:
		h_scene_cooldown -= delta

	if player.current_state == Player.State.GRABBED:
		handle_grabbed_state(delta)
	elif player.current_state == Player.State.RAPE:
		handle_rape_state(delta)

func handle_grabbed_state(delta: float) -> void:
	if qte_attacker and (not is_instance_valid(qte_attacker) or not qte_attacker.has_method("is_alive") or not qte_attacker.is_alive()):
		exit_grabbed_state_due_to_attacker_death()
		return

	# Apply friction/movement slowdown for player velocity in grabbed state
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta)
	if not player.is_on_floor():
		var active_gravity = player.gravity * player.fall_gravity_multiplier if player.velocity.y > 0 else player.gravity
		player.velocity.y += active_gravity * delta
	player.move_and_slide()

	# QTE decay
	var decay_multiplier = player.corruption_component.get_qte_decay_multiplier() if player.corruption_component else 2.0
	qte_progress = max(0.0, qte_progress - delta * qte_decay_rate * decay_multiplier)

	# Active H-scene updates
	if is_active:
		h_scene_timer += delta
		if h_scene_timer >= 5.0:
			h_scene_timer -= 5.0
			_on_h_scene_tick()

		if is_instance_valid(qte_attacker) and qte_attacker.is_alive():
			var offset_x = 45.0 if "Orc" in qte_attacker.name or qte_attacker.get_script().get_path().contains("orc") else 30.0
			var target_x = player.global_position.x + h_scene_direction * offset_x
			var target_y = player.global_position.y

			qte_attacker.global_position.x = lerp(qte_attacker.global_position.x, target_x, 15.0 * delta)
			qte_attacker.global_position.y = lerp(qte_attacker.global_position.y, target_y, 15.0 * delta)

			if player.has_node("Sprite2D"):
				player.get_node("Sprite2D").flip_h = h_scene_direction < 0
			var enemy_sprite = qte_attacker.get_node_or_null("Sprite2D")
			if enemy_sprite:
				enemy_sprite.flip_h = h_scene_direction > 0

	# Check for close-range trigger
	if not is_active:
		check_and_trigger_grabbed_h_scene()

	# Next key indicators
	var next_key := "any"
	if last_qte_key == "left":
		next_key = "right"
	elif last_qte_key == "right":
		next_key = "left"

	if player.qte_indicator:
		player.qte_indicator.set_qte_state(qte_progress, qte_target, next_key)

	# Alternating mashing inputs
	var left_pressed := Input.is_action_just_pressed("move_left")
	var right_pressed := Input.is_action_just_pressed("move_right")

	if left_pressed or right_pressed:
		var valid_input := false
		if left_pressed and last_qte_key != "left":
			last_qte_key = "left"
			valid_input = true
		elif right_pressed and last_qte_key != "right":
			last_qte_key = "right"
			valid_input = true

		if valid_input:
			var mash_gain := qte_mash_gain
			if player.skill_component and player.skill_component.is_skill_unlocked("H"):
				mash_gain = qte_upgraded_mash_gain
			qte_progress = min(qte_target, qte_progress + mash_gain)

			var next_after_press := "any"
			if last_qte_key == "left":
				next_after_press = "right"
			elif last_qte_key == "right":
				next_after_press = "left"

			if player.qte_indicator:
				player.qte_indicator.set_qte_state(qte_progress, qte_target, next_after_press, 8.0)

	# Success escape check
	if qte_progress >= qte_target:
		escape_grab()

func check_and_trigger_grabbed_h_scene() -> void:
	var enemies = player.get_tree().get_nodes_in_group("enemies")
	var target_enemy: Node2D = null

	# 1. Prioritize QTE attacker
	if is_instance_valid(qte_attacker) and qte_attacker.has_method("is_alive") and qte_attacker.is_alive():
		var dx = abs(player.global_position.x - qte_attacker.global_position.x)
		var dy = abs(player.global_position.y - qte_attacker.global_position.y)
		if dx <= qte_trigger_range_x and dy <= qte_trigger_range_y:
			target_enemy = qte_attacker

	# 2. Check nearby enemies
	if not target_enemy:
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.has_method("is_alive") and enemy.is_alive():
				var dx = abs(player.global_position.x - enemy.global_position.x)
				var dy = abs(player.global_position.y - enemy.global_position.y)
				if dx <= qte_trigger_range_x and dy <= qte_trigger_range_y:
					target_enemy = enemy
					break

	if target_enemy:
		is_active = true
		h_scene_timer = 0.0
		h_scene_direction = 1.0 if target_enemy.global_position.x > player.global_position.x else -1.0
		h_scene_triggered.emit(target_enemy)
		player.h_scene_triggered.emit(target_enemy) # Emit parent signal
		if player.has_node("Sprite2D"):
			player.get_node("Sprite2D").modulate = Color(1.0, 0.0, 0.0, 1.0)
		print("H-Scene Triggered with prioritized enemy: ", target_enemy.name)

func start_qte(attacker: Node2D) -> void:
	player.current_state = Player.State.GRABBED
	qte_attacker = attacker
	qte_progress = 0.0
	last_qte_key = ""
	is_active = false
	h_scene_timer = 0.0
	if player.has_node("Sprite2D"):
		player.get_node("Sprite2D").modulate = Color(1.0, 1.0, 0.0, 1.0) # Yellow modulation
	if player.qte_indicator:
		player.qte_indicator.visible = true
		player.qte_indicator.set_qte_state(0.0, qte_target, "any")

	# Attract attacker at full speed
	if is_instance_valid(qte_attacker) and qte_attacker.has_method("is_alive") and qte_attacker.is_alive():
		var existing = qte_attacker.get_node_or_null("AttractEffectComponent")
		if existing:
			existing.speed_multiplier = 1.0
			existing.duration = 8.0
			existing.refresh()
		else:
			var effect_script = load("res://scenes/enemies/components/attract_effect_component.gd")
			var effect = Node.new()
			effect.name = "AttractEffectComponent"
			effect.set_script(effect_script)
			effect.set("speed_multiplier", 1.0)
			effect.set("duration", 8.0)
			qte_attacker.add_child(effect)
		print("[QTE] Attracted attacker: ", qte_attacker.name, " at full speed.")

func escape_grab() -> void:
	player.current_state = Player.State.MOVE
	qte_attacker = null
	h_scene_timer = 0.0
	h_scene_cooldown = 2.0
	is_active = false
	if player.qte_indicator:
		player.qte_indicator.visible = false
	player.is_invincible = true
	player.invincibility_timer = qte_escape_invincibility_duration
	if player.has_node("Sprite2D"):
		player.get_node("Sprite2D").modulate = Color(1.0, 1.0, 1.0, 1.0)

func exit_grabbed_state_due_to_attacker_death() -> void:
	player.current_state = Player.State.MOVE
	qte_attacker = null
	h_scene_timer = 0.0
	h_scene_cooldown = 2.0
	is_active = false
	if player.qte_indicator:
		player.qte_indicator.visible = false
	player.is_invincible = true
	player.invincibility_timer = qte_escape_invincibility_duration
	if player.has_node("Sprite2D"):
		player.get_node("Sprite2D").modulate = Color(1.0, 1.0, 1.0, 1.0)
	print("[QTE] Attacker died, exiting grabbed state.")

func start_rape(enemy: Node2D) -> void:
	player.current_state = Player.State.RAPE
	rape_target_enemy = enemy
	rape_timer = 5.0
	is_active = true
	h_scene_timer = 0.0
	h_scene_direction = 1.0 if enemy.global_position.x > player.global_position.x else -1.0

	if is_instance_valid(enemy):
		enemy.set("is_being_raped", true)
		if player.has_node("Sprite2D"):
			player.get_node("Sprite2D").flip_h = h_scene_direction < 0
			player.get_node("Sprite2D").modulate = Color(1.0, 0.0, 0.0, 1.0)
		var enemy_sprite = enemy.get_node_or_null("Sprite2D")
		if enemy_sprite:
			enemy_sprite.flip_h = h_scene_direction > 0
		print("[RAPE] Started on ", enemy.name, ". Locked both and starting H-scene.")
		h_scene_triggered.emit(enemy)
		player.h_scene_triggered.emit(enemy) # Emit parent signal

func handle_rape_state(delta: float) -> void:
	player.velocity = Vector2.ZERO

	if not is_instance_valid(rape_target_enemy) or not rape_target_enemy.is_alive():
		exit_rape()
		return

	# Smoothly lerp PLAYER position adjacent to the ENEMY
	var offset_x = 45.0 if "Orc" in rape_target_enemy.name or rape_target_enemy.get_script().get_path().contains("orc") else 30.0
	var target_x = rape_target_enemy.global_position.x - h_scene_direction * offset_x
	var target_y = rape_target_enemy.global_position.y

	player.global_position.x = lerp(player.global_position.x, target_x, 15.0 * delta)
	player.global_position.y = lerp(player.global_position.y, target_y, 15.0 * delta)

	if player.has_node("Sprite2D"):
		player.get_node("Sprite2D").flip_h = h_scene_direction < 0
	var enemy_sprite = rape_target_enemy.get_node_or_null("Sprite2D")
	if enemy_sprite:
		enemy_sprite.flip_h = h_scene_direction > 0

	rape_timer -= delta
	if rape_timer <= 0.0:
		_on_h_scene_tick()

		if is_instance_valid(rape_target_enemy) and rape_target_enemy.is_alive():
			rape_timer = 5.0
			print("[RAPE] Enemy survived tick. Resetting rape timer for next tick.")
		else:
			var temp_enemy = rape_target_enemy
			exit_rape()

			var should_knockback = randf() < 0.5
			if should_knockback and is_instance_valid(temp_enemy):
				player.apply_knockback(temp_enemy.global_position, 300.0)
				print("[RAPE] Monster knocked player back on release.")

func exit_rape() -> void:
	player.current_state = Player.State.MOVE
	is_active = false
	h_scene_timer = 0.0
	h_scene_cooldown = 2.0
	if is_instance_valid(rape_target_enemy):
		rape_target_enemy.set("is_being_raped", false)
	rape_target_enemy = null
	if player.has_node("Sprite2D"):
		player.get_node("Sprite2D").modulate = Color(1.0, 1.0, 1.0, 1.0)
	print("[RAPE] Exited rape H-scene.")

func _on_h_scene_tick() -> void:
	if player.corruption_component:
		player.corruption_component.reduce_max_sanity(5.0)
		h_scene_tick.emit(player.corruption_component.max_sanity)
		player.h_scene_tick.emit(player.corruption_component.max_sanity) # Emit parent signal
		print("[H-SCENE TICK] Lost 5 max sanity. Current max sanity: ", player.corruption_component.max_sanity)

	var heal_amount := int(round(player.max_health * 0.25))
	if heal_amount > 0:
		player.current_health = min(player.max_health, player.current_health + heal_amount)
		player.health_changed.emit(player.current_health)
		print("[H-SCENE TICK] Recovered ", heal_amount, " HP. Current HP: ", player.current_health)

	var active_enemy: Node2D = null
	if player.current_state == Player.State.GRABBED:
		active_enemy = qte_attacker
	elif player.current_state == Player.State.RAPE:
		active_enemy = rape_target_enemy

	if is_instance_valid(active_enemy) and active_enemy.has_method("take_damage") and active_enemy.has_method("is_alive") and active_enemy.is_alive():
		var count = active_enemy.get("eruption_count")
		if count == null:
			count = 0
		count += 1
		active_enemy.set("eruption_count", count)

		var damage_amount: int
		if count >= 3:
			damage_amount = active_enemy.current_health
			print("[H-SCENE TICK] Eruption tick ", count, " (3rd tick). Dealing fatal damage of ", damage_amount, " to ", active_enemy.name)
		else:
			damage_amount = int(round(active_enemy.current_health * 0.5))
			print("[H-SCENE TICK] Eruption tick ", count, ". Dealt ", damage_amount, " damage to ", active_enemy.name, " (50% current HP).")

		# Trigger Screen Shake via camera component
		if player.camera_component:
			player.camera_component.start_eruption_shake(8.0, 0.8)
		if player.qte_indicator and player.qte_indicator.visible:
			player.qte_indicator.shake_amount = 8.0

		# Trigger Screen Flash
		var hud_nodes = player.get_tree().get_nodes_in_group("hud")
		for hud in hud_nodes:
			if hud.has_method("trigger_flash"):
				hud.trigger_flash(Color(1.0, 0.35, 0.65, 0.3), 0.2)

		# Spawn Eruption Particles
		if is_instance_valid(active_enemy):
			var midpoint = (player.global_position + active_enemy.global_position) * 0.5
			midpoint.y -= 10.0
			_spawn_eruption_particles(midpoint)

		active_enemy.take_damage(damage_amount, player.global_position, player)

func _spawn_eruption_particles(pos: Vector2) -> void:
	var particles = CPUParticles2D.new()
	particles.name = "EruptionParticles"
	particles.position = pos
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 25
	particles.lifetime = 0.6
	particles.explosiveness = 0.95
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2(0, 150.0)
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 150.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0

	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.4, 0.7, 1.0))
	gradient.add_point(0.4, Color(1.0, 0.85, 0.95, 1.0))
	gradient.set_color(1, Color(1.0, 0.3, 0.6, 0.0))
	particles.color_ramp = gradient

	player.get_parent().add_child(particles)
	particles.emitting = true

	var timer = player.get_tree().create_timer(1.0)
	timer.timeout.connect(particles.queue_free)

func reset() -> void:
	qte_attacker = null
	rape_target_enemy = null
	is_active = false
	h_scene_timer = 0.0
	qte_progress = 0.0
	last_qte_key = ""
