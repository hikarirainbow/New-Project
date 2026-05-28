class_name Player
extends Actor

# Basic movement parameters (configured for 2D platformers)
const SPEED           = 200.0
const JUMP_VELOCITY   = -450.0  # ~103px apex
const ACCELERATION    = 1000.0

# Finite State Machine (FSM) definition
enum State { MOVE, GRABBED, DEFEATED, DASH, CLIMB, RAPE }
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
@export var fall_gravity_multiplier: float = 1.5
@export var jump_cut_multiplier: float = 0.1

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
var attract_cast_timer: float = 0.0

var _force_triple_knockback: bool = false
var qte_indicator: Node2D = null

# Backward compatibility properties proxied to components
var keys: Array[String]:
	get:
		if inventory_component:
			return inventory_component.keys
		var empty: Array[String] = []
		return empty
	set(val):
		if inventory_component:
			inventory_component.keys = val

var _h_scene_active: bool:
	get:
		return h_scene_component.is_active if h_scene_component else false
	set(val):
		if h_scene_component:
			h_scene_component.is_active = val

var qte_attacker: Node2D:
	get:
		return h_scene_component.qte_attacker if h_scene_component else null
	set(val):
		if h_scene_component:
			h_scene_component.qte_attacker = val

var qte_progress: float:
	get:
		return h_scene_component.qte_progress if h_scene_component else 0.0
	set(val):
		if h_scene_component:
			h_scene_component.qte_progress = val

var qte_target: float:
	get:
		return h_scene_component.qte_target if h_scene_component else 100.0
	set(val):
		if h_scene_component:
			h_scene_component.qte_target = val

var last_qte_key: String:
	get:
		return h_scene_component.last_qte_key if h_scene_component else ""
	set(val):
		if h_scene_component:
			h_scene_component.last_qte_key = val

var rape_target_enemy: Node2D:
	get:
		return h_scene_component.rape_target_enemy if h_scene_component else null
	set(val):
		if h_scene_component:
			h_scene_component.rape_target_enemy = val

var rape_timer: float:
	get:
		return h_scene_component.rape_timer if h_scene_component else 0.0
	set(val):
		if h_scene_component:
			h_scene_component.rape_timer = val

var h_scene_timer: float:
	get:
		return h_scene_component.h_scene_timer if h_scene_component else 0.0
	set(val):
		if h_scene_component:
			h_scene_component.h_scene_timer = val

var h_scene_direction: float:
	get:
		return h_scene_component.h_scene_direction if h_scene_component else 1.0
	set(val):
		if h_scene_component:
			h_scene_component.h_scene_direction = val

var h_scene_cooldown: float:
	get:
		return h_scene_component.h_scene_cooldown if h_scene_component else 0.0
	set(val):
		if h_scene_component:
			h_scene_component.h_scene_cooldown = val

var camera_look_offset_y: float:
	get:
		return camera_component.camera_look_offset_y if camera_component else 0.0
	set(val):
		if camera_component:
			camera_component.camera_look_offset_y = val

var camera_shake_timer: float:
	get:
		return camera_component.camera_shake_timer if camera_component else 0.0
	set(val):
		if camera_component:
			camera_component.camera_shake_timer = val

var camera_shake_intensity: float:
	get:
		return camera_component.camera_shake_intensity if camera_component else 0.0
	set(val):
		if camera_component:
			camera_component.camera_shake_intensity = val

# Custom signal emitted on player defeat
signal player_defeated
# Key pickup signal
signal key_collected(key_name: String)
signal h_scene_triggered(enemy_node: Node2D)
signal h_scene_tick(new_max_sanity: float)

var spawn_point: Vector2

# Cached child component references
@onready var attack_component = $AttackComponent
@onready var dash_component = $DashComponent
@onready var climb_component = $ClimbComponent
@onready var animation_component = $AnimationComponent
@onready var corruption_component = $CorruptionComponent
@onready var skill_component = $SkillComponent

# Newly registered components
@onready var camera_component = $CameraComponent
@onready var h_scene_component = $HSceneComponent
@onready var inventory_component = $InventoryComponent

func _ready() -> void:
	add_to_group("player")
	spawn_point = global_position
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

	if attract_cast_timer > 0.0:
		attract_cast_timer -= delta
		
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
		State.GRABBED, State.RAPE:
			# Handled by HSceneComponent's physics process
			pass
		State.DEFEATED:
			handle_defeated_state(delta)
		State.DASH:
			dash_component.process_dash(delta)
		State.CLIMB:
			climb_component.process_climb(delta)

# Logic loop for free movement state
func handle_move_state(delta: float) -> void:
	# If casting attract skill, lock control/movement and lock direction
	if attract_cast_timer > 0.0:
		if is_on_floor():
			velocity.x = 0.0
		if not is_on_floor():
			var active_gravity = gravity * fall_gravity_multiplier if velocity.y > 0 else gravity
			velocity.y += active_gravity * delta
		move_and_slide()
		return

	# Check for special H-scene (rape) trigger (only when player is grounded and cooldown is inactive)
	if Input.is_action_just_pressed("skill_rape") and h_scene_cooldown <= 0.0 and is_on_floor():
		var enemies = get_tree().get_nodes_in_group("enemies")
		var closest_enemy: Node2D = null
		var min_dist = 150.0 # Max trigger range
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.has_method("is_alive") and enemy.is_alive():
				if enemy.get("current_state") == 3: # 3 = State.ATTRACTED
					if enemy.has_method("is_on_floor") and enemy.is_on_floor():
						var dist = global_position.distance_to(enemy.global_position)
						if dist < min_dist:
							min_dist = dist
							closest_enemy = enemy
		if closest_enemy:
			start_rape(closest_enemy)
			return

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

# QTE delegation
func start_qte() -> void:
	if h_scene_component:
		h_scene_component.start_qte(qte_attacker)

# Rape state delegation
func start_rape(enemy: Node2D) -> void:
	if h_scene_component:
		h_scene_component.start_rape(enemy)

func exit_rape() -> void:
	if h_scene_component:
		h_scene_component.exit_rape()

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
	attract_cast_timer = 0.0
	var attract_skill = get_node_or_null("AttractSkillComponent")
	if attract_skill:
		attract_skill.cone_alpha = 0.0
	
	var is_below_half_hp = current_health < max_health * 0.5
	var would_survive = (current_health - final_amount) > 0
	
	var is_grounded = is_on_floor()
	var is_attacker_grounded = false
	if is_instance_valid(attacker) and attacker is CharacterBody2D:
		is_attacker_grounded = attacker.is_on_floor()
		
	var should_trigger_qte = is_below_half_hp and would_survive and h_scene_cooldown <= 0.0 and is_grounded and is_attacker_grounded
	
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

# Respawn player at original spawn point coordinates
func respawn() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	knockback_timer = 0.0
	invincibility_timer = 0.0
	is_invincible = false
	current_health += 9999
	apply_debuff()
	current_state = State.MOVE
	dash_component.reset()
	
	if h_scene_component:
		h_scene_component.reset()
		
	# Hide above-head QTE indicators if active on death
	if qte_indicator:
		qte_indicator.visible = false

# Dash upgrade callback: reduces dash cooldown duration by half
func upgrade_dash_cooldown() -> void:
	dash_component.upgrade_cooldown()

# Key collection callback (proxies to InventoryComponent)
func collect_key(key_name: String) -> void:
	if inventory_component:
		inventory_component.collect_key(key_name)

# Trigger hit stop (time freeze) on successful impact
func trigger_hit_stop(duration: float = 0.08, time_scale: float = 0.05) -> void:
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

# Camera helper functions proxied to CameraComponent
func shake_camera(direction_x: float, intensity: float = 8.0, duration: float = 0.15) -> void:
	if camera_component:
		camera_component.shake_camera(direction_x, intensity, duration)

func is_h_scene_active() -> bool:
	return h_scene_component.is_active if h_scene_component else false
