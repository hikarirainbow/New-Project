class_name DashComponent
extends Node

const DASH_SPEED = 600.0
const DASH_DURATION = 0.2
const DASH_ACTIVE_DURATION = 0.18

var dash_cooldown = 0.8
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = Vector2.ZERO

@onready var player = get_parent()

func _physics_process(delta: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

func can_dash() -> bool:
	return dash_cooldown_timer <= 0.0

func start_dash() -> void:
	player.current_state = 3 # State.DASH
	dash_timer = 0.0
	dash_cooldown_timer = dash_cooldown
	
	var dir = Input.get_axis("move_left", "move_right")
	if dir == 0.0:
		dir = -1.0 if (player.has_node("Sprite2D") and player.get_node("Sprite2D").flip_h) else 1.0
		
	dash_direction = Vector2(dir, 0.0).normalized()
	
	if player.has_node("Sprite2D"):
		player.get_node("Sprite2D").flip_h = dash_direction.x < 0
		
	player.velocity.x = dash_direction.x * DASH_SPEED
	player.velocity.y = 0.0
	player.is_invincible = true

func process_dash(delta: float) -> void:
	dash_timer += delta
	
	if dash_timer < DASH_ACTIVE_DURATION:
		player.velocity.x = dash_direction.x * DASH_SPEED
		player.velocity.y = 0.0
		player.is_invincible = true
	elif dash_timer < DASH_DURATION:
		player.is_invincible = false
		
		# Khóa hướng di chuyển
		var input_dir = Input.get_axis("move_left", "move_right")
		var target_speed = 0.0
		if sign(input_dir) == sign(dash_direction.x):
			# Refers to SPEED constant on Player
			target_speed = dash_direction.x * 200.0 # SPEED
			
		var recovery_time_passed = dash_timer - DASH_ACTIVE_DURATION
		var total_recovery_time = DASH_DURATION - DASH_ACTIVE_DURATION
		var t = recovery_time_passed / total_recovery_time
		
		player.velocity.x = lerp(dash_direction.x * DASH_SPEED, target_speed, t)
		
		if not player.is_on_floor():
			player.velocity.y += player.gravity * delta
	else:
		player.is_invincible = false
		player.current_state = 0 # State.MOVE
		
	player.move_and_slide()

func interrupt() -> void:
	if player.current_state == 3: # State.DASH
		player.is_invincible = false
		player.current_state = 0 # State.MOVE

func reset() -> void:
	dash_cooldown_timer = 0.0

func upgrade_cooldown() -> void:
	dash_cooldown = dash_cooldown / 2.0
