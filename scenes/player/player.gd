class_name Player
extends Actor

# Basic movement parameters (configured for 2D platformers)
const SPEED           = 200.0
const JUMP_VELOCITY   = -450.0  # ~103px apex
const ACCELERATION    = 1000.0

# Finite State Machine (FSM) definition
enum State { MOVE, GRABBED, DEFEATED, DASH, CLIMB }
var current_state = State.MOVE

# Player-specific debuff status
var is_debuffed = false

# Invincibility frame settings
@export_group("Invincibility & Flash")
@export var damage_invincibility_duration: float = 0.5
@export var flash_rate_divisor: int = 10
@export var flash_threshold: int = 5
@export var flash_opacity: float = 0.4

@export_group("Struggling & QTE")
@export var qte_indicator_offset: Vector2 = Vector2(0, -82)
@export var default_camera_zoom: Vector2 = Vector2(2.4, 2.4)
@export var camera_look_pan_distance: float = 200.0
@export var camera_look_pan_speed: float = 5.0
@export var fall_gravity_multiplier: float = 1.5
@export var jump_cut_multiplier: float = 0.1
@export var qte_decay_rate: float = 22.5
@export var qte_trigger_range_x: float = 10.0
@export var qte_trigger_range_y: float = 20.0
@export var qte_mash_gain: float = 10.0
@export var qte_upgraded_mash_gain: float = 15.0
@export var qte_escape_invincibility_duration: float = 0.5

@export_group("Health Values")
@export var debuffed_max_health: int = 80
@export var standard_max_health: int = 100

@export_group("Combat Recoil")
@export var melee_recoil_duration: float = 0.08

var invincibility_timer = 0.0
var is_invincible = false
var recoil_timer: float = 0.0
var is_at_checkpoint: bool = false
var has_double_jumped: bool = false

# Quick Time Event (QTE) tracking variables
var qte_progress: float = 0.0
var qte_target: float = 100.0
var last_qte_key: String = ""
var _force_triple_knockback: bool = false
var qte_indicator: Node2D = null
var _h_scene_active: bool = false
var qte_attacker: Node2D = null
var h_scene_timer: float = 0.0

# Custom signal emitted on player defeat
signal player_defeated
# Key pickup signal
signal key_collected(key_name: String)
signal h_scene_triggered(enemy_node: Node2D)
signal h_scene_tick(new_max_sanity: float)

# Collected keys storage
var keys: Array[String] = []
var spawn_point: Vector2

# Cached child component references
@onready var attack_component = $AttackComponent
@onready var dash_component = $DashComponent
@onready var climb_component = $ClimbComponent
@onready var animation_component = $AnimationComponent
@onready var corruption_component = $CorruptionComponent
@onready var skill_component = $SkillComponent

func _ready() -> void:
	add_to_group("player")
	spawn_point = global_position
	if has_node("Camera2D"): 
		$Camera2D.zoom = default_camera_zoom
	# Capture mouse mode on game start
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Programmatically instantiate and anchor QTE indicator above head (50px offset from sprite top)
	qte_indicator = Node2D.new()
	qte_indicator.name = "QTEIndicator"
	qte_indicator.set_script(load("res://scenes/player/qte_indicator.gd"))
	qte_indicator.visible = false
	qte_indicator.position = qte_indicator_offset
	add_child(qte_indicator)

	# Programmatically instantiate and anchor Attract Skill Component
	var attract_skill = Node2D.new()
	attract_skill.name = "AttractSkillComponent"
	attract_skill.set_script(load("res://scenes/player/components/attract_skill_component.gd"))
	add_child(attract_skill)

func _physics_process(delta: float) -> void:
	if knockback_timer > 0.0:
		knockback_timer -= delta

	if recoil_timer > 0.0:
		recoil_timer -= delta
		
	# Process invincibility timer and sprite flashing effect
	if invincibility_timer > 0.0:
		invincibility_timer -= delta
		if has_node("Sprite2D"):
			$Sprite2D.modulate.a = flash_opacity if Engine.get_frames_drawn() % flash_rate_divisor < flash_threshold else 1.0
		if invincibility_timer <= 0.0:
			is_invincible = false
			if has_node("Sprite2D"):
				$Sprite2D.modulate.a = 1.0
			
	match current_state:
		State.MOVE:
			handle_move_state(delta)
		State.GRABBED:
			handle_grabbed_state(delta)
		State.DEFEATED:
			handle_defeated_state(delta)
		State.DASH:
			dash_component.process_dash(delta)
		State.CLIMB:
			climb_component.process_climb(delta)
			
	_update_camera_look(delta)

# Logic loop for free movement state
func handle_move_state(delta: float) -> void:
	# If attacking, lock control direction and brake horizontal movement on floor
	if attack_component.is_attacking():
		if is_on_floor() and recoil_timer <= 0.0:
			velocity.x = 0.0
		if not is_on_floor():
			var active_gravity = gravity * fall_gravity_multiplier if velocity.y > 0 else gravity
			velocity.y += active_gravity * delta
		move_and_slide()
		return

	# Trigger attack chain when attack action is input
	if Input.is_action_just_pressed("attack") and attack_component.can_attack():
		attack_component.start_attack()
		return

	# Trigger dash sequence when dash action is input and cooldown is zero
	if Input.is_action_just_pressed("dash") and dash_component.can_dash():
		dash_component.start_dash()
		return

	# Apply gravity acceleration
	if not is_on_floor():
		# Fall gravity is scaled to create a heavier platforming feel
		var active_gravity = gravity * fall_gravity_multiplier if velocity.y > 0 else gravity
		velocity.y += active_gravity * delta
		
		# Auto-climb: trigger when holding directional input towards the wall we are facing
		var dir := Input.get_axis("move_left", "move_right")
		var is_facing_left: bool = $Sprite2D.flip_h if has_node("Sprite2D") else false
		var input_towards_wall := (dir < 0 and is_facing_left) or (dir > 0 and not is_facing_left)
		if input_towards_wall:
			var ledge_data = climb_component.check_ledge()
			if not ledge_data.is_empty():
				climb_component.start_climb(ledge_data.target_position)
				return

	# Variable jump height: release jump button early to scale upwards velocity (min jump ~5px)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	# If locked in knockback state, damp horizontal velocity via friction and ignore inputs
	if knockback_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		move_and_slide()
		return

	if is_on_floor():
		has_double_jumped = false

	# Jump or double jump checks if airborne
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		else:
			if skill_component and skill_component.is_skill_unlocked("F") and not has_double_jumped:
				velocity.y = JUMP_VELOCITY
				has_double_jumped = true

	# Query directional horizontal inputs
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		# Linearly interpolate horizontal velocity towards target max speed
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		# Update sprite flip direction matching velocity sign
		if has_node("Sprite2D"):
			$Sprite2D.flip_h = direction < 0
	else:
		# Linearly decelerate velocity to 0 when no direction is input
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	move_and_slide()

# Logic loop for grabbed state (QTE active)
func handle_grabbed_state(delta: float) -> void:
	# Apply standard gravity in grabbed state
	if not is_on_floor():
		var active_gravity = gravity * fall_gravity_multiplier if velocity.y > 0 else gravity
		velocity.y += active_gravity * delta

	# Decay horizontal velocity via friction
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	move_and_slide()
	
	# QTE progress decays linearly over time scaled by the sanity/corruption component decay multiplier
	var decay_multiplier = corruption_component.get_qte_decay_multiplier() if corruption_component else 2.0
	qte_progress = max(0.0, qte_progress - delta * qte_decay_rate * decay_multiplier)
	
	# H-Scene processing
	if _h_scene_active:
		h_scene_timer += delta
		if h_scene_timer >= 5.0:
			h_scene_timer -= 5.0
			_on_h_scene_tick()
	
	# Check for close-range enemy H-scene trigger
	if not _h_scene_active:
		var enemies = get_tree().get_nodes_in_group("enemies")
		var target_enemy: Node2D = null
		
		# 1. First check if the prioritized QTE attacker is within range
		if is_instance_valid(qte_attacker) and qte_attacker.has_method("is_alive") and qte_attacker.is_alive():
			var dx = abs(global_position.x - qte_attacker.global_position.x)
			var dy = abs(global_position.y - qte_attacker.global_position.y)
			if dx <= qte_trigger_range_x and dy <= qte_trigger_range_y:
				target_enemy = qte_attacker
				
		# 2. If not, fallback to other close-range enemies
		if not target_enemy:
			for enemy in enemies:
				if is_instance_valid(enemy) and enemy.has_method("is_alive") and enemy.is_alive():
					var dx = abs(global_position.x - enemy.global_position.x)
					var dy = abs(global_position.y - enemy.global_position.y)
					if dx <= qte_trigger_range_x and dy <= qte_trigger_range_y:
						target_enemy = enemy
						break
						
		if target_enemy:
			_h_scene_active = true
			h_scene_timer = 0.0
			h_scene_triggered.emit(target_enemy)
			if has_node("Sprite2D"):
				$Sprite2D.modulate = Color(1.0, 0.0, 0.0, 1.0) # Turn red for H-scene trigger
			print("H-Scene Triggered with prioritized enemy: ", target_enemy.name)

	# Calculate target input key instruction for HUD arrows
	var next_key := "any"
	if last_qte_key == "left":
		next_key = "right"
	elif last_qte_key == "right":
		next_key = "left"
		
	if qte_indicator:
		qte_indicator.set_qte_state(qte_progress, qte_target, next_key)
		
	# Check for alternation inputs (Left/Right inputs)
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
			if skill_component and skill_component.is_skill_unlocked("H"):
				mash_gain = qte_upgraded_mash_gain # stronger struggling power
			qte_progress = min(qte_target, qte_progress + mash_gain)
			
			var next_after_press := "any"
			if last_qte_key == "left":
				next_after_press = "right"
			elif last_qte_key == "right":
				next_after_press = "left"
				
			if qte_indicator:
				qte_indicator.set_qte_state(qte_progress, qte_target, next_after_press, 8.0)
				
	# Successful QTE exit
	if qte_progress >= qte_target:
		current_state = State.MOVE
		qte_attacker = null
		h_scene_timer = 0.0
		if qte_indicator:
			qte_indicator.visible = false
		# Grant player invincibility buffer upon escape
		is_invincible = true
		invincibility_timer = qte_escape_invincibility_duration
		if has_node("Sprite2D"):
			$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)

# Initialize QTE sequence
func start_qte() -> void:
	current_state = State.GRABBED
	qte_progress = 0.0
	last_qte_key = ""
	_h_scene_active = false
	h_scene_timer = 0.0
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1.0, 1.0, 0.0, 1.0) # Modulate yellow for testing visual state identification
	if qte_indicator:
		qte_indicator.visible = true
		qte_indicator.set_qte_state(0.0, qte_target, "any")
		
	# Attract the QTE attacker at full speed (no speed reduction, longer duration)
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

# Override Actor.apply_knockback to support scaled 3x force during grabbed/QTE triggers
func apply_knockback(source_position: Vector2, force: float = 250.0) -> void:
	var actual_force = force
	var actual_upward = 0.0 # Standard knockback has zero Y bounce
	var actual_duration = knockback_duration
	
	if _force_triple_knockback:
		actual_force = force * 3.0
		actual_upward = -350.0  # Launch player higher upward for QTE
		actual_duration = 0.5   # Prolong input lock duration
		
	var push_dir = 1.0 if global_position.x > source_position.x else -1.0
	velocity.x = push_dir * actual_force
	velocity.y = actual_upward
	knockback_timer = actual_duration

# Defeated state logic loop
func handle_defeated_state(delta: float) -> void:
	# Pull down to floor if airborne
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = 0
	move_and_slide()

# Process incoming damage (overrides parent Actor method to add state verification)
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO, attacker: Node2D = null) -> void:
	if current_state == State.DEFEATED or current_state == State.GRABBED or is_invincible:
		return
		
	# Scale incoming damage by corruption-based defense multiplier
	var final_amount = amount
	if corruption_component:
		final_amount = int(round(amount * corruption_component.get_defense_multiplier()))
		# Subtract sanity when attacked (doubled penalty)
		corruption_component.subtract_sanity(final_amount * 2.0)

	# Interrupt active actions on hit
	attack_component.interrupt()
	dash_component.interrupt()
	climb_component.interrupt()
	
	var is_below_half_hp = current_health < max_health * 0.5
	var would_survive = (current_health - final_amount) > 0
	var should_trigger_qte = is_below_half_hp and would_survive
	
	if should_trigger_qte:
		_force_triple_knockback = true
		qte_attacker = attacker
		
	super(final_amount, source_position, attacker)
	
	# Apply Skill I: Hurt Reflection (reflect 30% of final_amount back to nearby enemies)
	if skill_component and skill_component.is_skill_unlocked("I"):
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.has_method("take_damage") and enemy.is_alive():
				if global_position.distance_to(enemy.global_position) < 64.0:
					var reflect_damage = int(round(final_amount * 0.3))
					if reflect_damage > 0:
						enemy.take_damage(reflect_damage, global_position)
						print("[SKILL] Reflected ", reflect_damage, " damage to: ", enemy.name)
	
	if should_trigger_qte:
		_force_triple_knockback = false
		start_qte()
	else:
		# Apply invincibility buffer on standard hit survival
		if current_health > 0:
			is_invincible = true
			invincibility_timer = damage_invincibility_duration

# Defeat sequence
func die() -> void:
	# Clear any previous corpses
	var old_corpses = get_tree().get_nodes_in_group("player_corpse")
	for old_corpse in old_corpses:
		if is_instance_valid(old_corpse):
			old_corpse.queue_free()
			
	# Spawn new player corpse
	var corpse_scene = load("res://scenes/player/player_corpse.tscn")
	if corpse_scene:
		var corpse = corpse_scene.instantiate()
		corpse.global_position = global_position
		corpse.max_health = max_health
		corpse.current_health = max_health
		get_parent().call_deferred("add_child", corpse)
		print("[DEATH] Spawned player corpse at: ", global_position, " with health: ", max_health)

	current_state = State.DEFEATED
	player_defeated.emit()
	print("Player has been defeated!")

# Apply debuff status (respawn consequence)
func apply_debuff() -> void:
	is_debuffed = true
	max_health = debuffed_max_health
	current_health = min(current_health, max_health)
	health_changed.emit(current_health)

# Clear debuff status (save room recovery)
func remove_debuff() -> void:
	is_debuffed = false
	max_health = standard_max_health
	current_health = max_health
	health_changed.emit(current_health)
	
	# Restore max sanity to normal (100) on soul shard/checkpoint recovery
	if corruption_component:
		corruption_component.max_sanity = 100.0
		corruption_component.add_sanity(0.0) # Refresh sanity HUD/modulate

func _on_h_scene_tick() -> void:
	if corruption_component:
		corruption_component.reduce_max_sanity(5.0)
		h_scene_tick.emit(corruption_component.max_sanity)
		print("[H-SCENE TICK] Lost 5 max sanity. Current max sanity: ", corruption_component.max_sanity)

# Respawn player at original spawn point coordinates
func respawn() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	knockback_timer = 0.0
	invincibility_timer = 0.0
	is_invincible = false
	qte_attacker = null
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
	current_health += 9999
	apply_debuff()
	current_state = State.MOVE
	dash_component.reset()
	
	# Hide above-head QTE indicators if active on death
	if qte_indicator:
		qte_indicator.visible = false

# Dash upgrade callback: reduces dash cooldown duration by half
func upgrade_dash_cooldown() -> void:
	dash_component.upgrade_cooldown()

# Key collection callback
func collect_key(key_name: String) -> void:
	keys.append(key_name)
	key_collected.emit(key_name)
	print("Key collected: ", key_name, " | Total keys: ", keys)

# Trigger hit stop (time freeze) on successful impact
func trigger_hit_stop(duration: float = 0.08, time_scale: float = 0.05) -> void:
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

# Shake camera opposite to slash direction
func shake_camera(direction_x: float, intensity: float = 8.0, duration: float = 0.15) -> void:
	var camera = get_node_or_null("Camera2D")
	if camera:
		camera.offset.x = -direction_x * intensity
		var tween = create_tween().set_ignore_time_scale(true)
		tween.tween_property(camera, "offset:x", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# Update camera look offset based on player input (look_up / look_down)
func _update_camera_look(delta: float) -> void:
	var camera = get_node_or_null("Camera2D")
	if not camera:
		return
		
	var target_offset_y = 0.0
	if current_state == State.MOVE:
		if not attack_component.is_attacking():
			if Input.is_action_pressed("look_up"):
				target_offset_y -= camera_look_pan_distance
			if Input.is_action_pressed("look_down"):
				target_offset_y += camera_look_pan_distance
				
	camera.offset.y = lerp(camera.offset.y, target_offset_y, camera_look_pan_speed * delta)

# Apply recoil pushback on melee hit
func apply_melee_recoil(direction_x: float, force: float = 160.0) -> void:
	# Recoil pushback in opposite direction of slash
	velocity.x = -direction_x * force
	recoil_timer = melee_recoil_duration
	move_and_slide()
