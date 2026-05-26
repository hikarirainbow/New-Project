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
@export var damage_invincibility_duration: float = 0.5
var invincibility_timer = 0.0
var is_invincible = false

# Quick Time Event (QTE) tracking variables
var qte_progress: float = 0.0
var qte_target: float = 100.0
var last_qte_key: String = ""
var _force_triple_knockback: bool = false
var qte_indicator: Node2D = null
var _h_scene_active: bool = false

# Custom signal emitted on player defeat
signal player_defeated
# Key pickup signal
signal key_collected(key_name: String)
signal h_scene_triggered(enemy_node: Node2D)

# Collected keys storage
var keys: Array[String] = []
var spawn_point: Vector2

# Cached child component references
@onready var attack_component = $AttackComponent
@onready var dash_component = $DashComponent
@onready var climb_component = $ClimbComponent
@onready var animation_component = $AnimationComponent
@onready var corruption_component = $CorruptionComponent



func _ready():
	add_to_group("player")
	spawn_point = global_position
	if has_node("Camera2D"): $Camera2D.zoom = Vector2(1.2, 1.2)
	# Capture mouse mouse mode on game start
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Programmatically instantiate and anchor QTE indicator above head (50px offset from sprite top)
	qte_indicator = Node2D.new()
	qte_indicator.name = "QTEIndicator"
	qte_indicator.set_script(load("res://scenes/player/qte_indicator.gd"))
	qte_indicator.visible = false
	qte_indicator.position = Vector2(0, -82) # Y = -32 (sprite top) - 50px = -82
	add_child(qte_indicator)

func _physics_process(delta):
	if knockback_timer > 0.0:
		knockback_timer -= delta
		
	# Process invincibility timer and sprite flashing effect
	if invincibility_timer > 0.0:
		invincibility_timer -= delta
		if has_node("Sprite2D"):
			$Sprite2D.modulate.a = 0.4 if Engine.get_frames_drawn() % 10 < 5 else 1.0
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

# Logic loop for free movement state
func handle_move_state(delta):
	# If attacking, lock control direction and brake horizontal movement on floor
	if attack_component.is_attacking():
		if is_on_floor():
			velocity.x = 0.0
		if not is_on_floor():
			var active_gravity = gravity * 1.5 if velocity.y > 0 else gravity
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
		# Fall gravity is scaled by 1.5x to create a heavier platforming feel
		var active_gravity = gravity * 1.5 if velocity.y > 0 else gravity
		velocity.y += active_gravity * delta

	# Variable jump height: release jump button early to scale upwards velocity by 0.1x (min jump ~5px)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.1

	# If locked in knockback state, damp horizontal velocity via friction and ignore inputs
	if knockback_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		move_and_slide()
		return

	# Jump or trigger ledge climb sequence if airborne
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		else:
			var ledge_data = climb_component.check_ledge()
			if not ledge_data.is_empty():
				climb_component.start_climb(ledge_data.target_position)
				return

	# Query directional horizontal inputs
	var direction = Input.get_axis("move_left", "move_right")
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
func handle_grabbed_state(delta):
	# Apply standard gravity in grabbed state
	if not is_on_floor():
		var active_gravity = gravity * 1.5 if velocity.y > 0 else gravity
		velocity.y += active_gravity * delta

	# Decay horizontal velocity via friction
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	move_and_slide()
	
	# QTE progress decays linearly over time scaled by the sanity/corruption component decay multiplier (halved rate = 22.5)
	var decay_multiplier = corruption_component.get_qte_decay_multiplier() if corruption_component else 2.0
	qte_progress = max(0.0, qte_progress - delta * 22.5 * decay_multiplier)
	
	# Check for close-range (5px) enemy H-scene trigger
	if not _h_scene_active:
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.has_method("is_alive") and enemy.is_alive():
				var dist = global_position.distance_to(enemy.global_position)
				if dist <= 5.0:
					_h_scene_active = true
					emit_signal("h_scene_triggered", enemy)
					print("H-Scene Triggered with enemy: ", enemy.name)
					break

	# Calculate target input key instruction for HUD arrows
	var next_key = "any"
	if last_qte_key == "left":
		next_key = "right"
	elif last_qte_key == "right":
		next_key = "left"
		
	if qte_indicator:
		qte_indicator.set_qte_state(qte_progress, qte_target, next_key)
		
	# Check for alternation inputs (Left/Right inputs)
	var left_pressed = Input.is_action_just_pressed("move_left")
	var right_pressed = Input.is_action_just_pressed("move_right")
	
	if left_pressed or right_pressed:
		var valid_input = false
		if left_pressed and last_qte_key != "left":
			last_qte_key = "left"
			valid_input = true
		elif right_pressed and last_qte_key != "right":
			last_qte_key = "right"
			valid_input = true
			
		if valid_input:
			qte_progress = min(qte_target, qte_progress + 10.0)
			
			var next_after_press = "any"
			if last_qte_key == "left":
				next_after_press = "right"
			elif last_qte_key == "right":
				next_after_press = "left"
				
			if qte_indicator:
				qte_indicator.set_qte_state(qte_progress, qte_target, next_after_press, 8.0)
				
	# Successful QTE exit
	if qte_progress >= qte_target:
		current_state = State.MOVE
		if qte_indicator:
			qte_indicator.visible = false
		# Grant player 0.5s invincibility buffer upon escape
		is_invincible = true
		invincibility_timer = 0.5
		if has_node("Sprite2D"):
			$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)

# Initialize QTE sequence
func start_qte():
	current_state = State.GRABBED
	qte_progress = 0.0
	last_qte_key = ""
	_h_scene_active = false
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1.0, 1.0, 0.0, 1.0) # Modulate yellow for testing visual state identification
	if qte_indicator:
		qte_indicator.visible = true
		qte_indicator.set_qte_state(0.0, qte_target, "any")


# Override Actor.apply_knockback to support scaled 3x force during grabbed/QTE triggers
func apply_knockback(source_position: Vector2, force: float = 250.0):
	var actual_force = force
	var actual_upward = -180.0
	var actual_duration = 0.25
	
	if _force_triple_knockback:
		actual_force = force * 3.0
		actual_upward = -350.0  # Launch player higher upward
		actual_duration = 0.5   # Prolong input lock duration
		
	var direction = (global_position - source_position).normalized()
	if abs(direction.x) < 0.1:
		direction.x = 1.0 if randf() > 0.5 else -1.0
	velocity.x = direction.x * actual_force
	velocity.y = actual_upward
	knockback_timer = actual_duration

# Defeated state logic loop
func handle_defeated_state(delta):
	# Pull down to floor if airborne
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = 0
	move_and_slide()

# Process incoming damage (overrides parent Actor method to add state verification)
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO):
	if current_state == State.DEFEATED or current_state == State.GRABBED or is_invincible:
		return
		
	# Scale incoming damage by corruption-based defense multiplier
	var final_amount = amount
	if corruption_component:
		final_amount = int(round(amount * corruption_component.get_defense_multiplier()))
		# Subtract sanity when attacked (doubled penalty = 2x final damage)
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
		
	super(final_amount, source_position)
	
	if should_trigger_qte:
		_force_triple_knockback = false
		start_qte()
	else:
		# Apply invincibility buffer on standard hit survival
		if current_health > 0:
			is_invincible = true
			invincibility_timer = damage_invincibility_duration

# Defeat sequence
func die():
	current_state = State.DEFEATED
	emit_signal("player_defeated")
	print("Player has been defeated!")

# Apply debuff status (respawn consequence)
func apply_debuff():
	is_debuffed = true
	max_health = 80
	current_health = min(current_health, max_health)
	emit_signal("health_changed", current_health)

# Clear debuff status (save room recovery)
func remove_debuff():
	is_debuffed = false
	max_health = 100
	current_health = max_health
	emit_signal("health_changed", current_health)

# Respawn player at original spawn point coordinates
func respawn():
	global_position = spawn_point
	velocity = Vector2.ZERO
	knockback_timer = 0.0
	invincibility_timer = 0.0
	is_invincible = false
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
func upgrade_dash_cooldown():
	dash_component.upgrade_cooldown()

# Key collection callback
func collect_key(key_name: String):
	keys.append(key_name)
	emit_signal("key_collected", key_name)
	print("Key collected: ", key_name, " | Total keys: ", keys)
