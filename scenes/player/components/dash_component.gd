class_name DashComponent
extends Node

@export_group("Dash Physics")
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_active_duration: float = 0.18
@export var base_dash_cooldown: float = 0.8
@export var skill_d_speed_multiplier: float = 1.4

var dash_cooldown: float = 0.8
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var extra_dash_used: bool = false

@onready var player: Player = get_parent() as Player

func _ready() -> void:
	dash_cooldown = base_dash_cooldown

func _physics_process(delta: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	if player.is_on_floor():
		extra_dash_used = false

func can_dash() -> bool:
	if dash_cooldown_timer <= 0.0:
		return true
	if player.skill_component and player.skill_component.is_skill_unlocked("E") and not extra_dash_used:
		return true
	return false

func start_dash() -> void:
	player.current_state = Player.State.DASH
	dash_timer = 0.0
	
	if dash_cooldown_timer > 0.0:
		extra_dash_used = true
		
	dash_cooldown_timer = dash_cooldown
	
	var dir := Input.get_axis("move_left", "move_right")
	if dir == 0.0:
		dir = -1.0 if (player.has_node("Sprite2D") and player.get_node("Sprite2D").flip_h) else 1.0
		
	dash_direction = Vector2(dir, 0.0).normalized()
	
	if player.has_node("Sprite2D"):
		player.get_node("Sprite2D").flip_h = dash_direction.x < 0
		
	var speed := dash_speed
	if player.skill_component and player.skill_component.is_skill_unlocked("D"):
		speed = dash_speed * skill_d_speed_multiplier
		
	player.velocity.x = dash_direction.x * speed
	player.velocity.y = 0.0
	player.is_invincible = true

func process_dash(delta: float) -> void:
	dash_timer += delta
	
	var speed := dash_speed
	if player.skill_component and player.skill_component.is_skill_unlocked("D"):
		speed = dash_speed * skill_d_speed_multiplier
		
	if dash_timer < dash_active_duration:
		player.velocity.x = dash_direction.x * speed
		player.velocity.y = 0.0
		player.is_invincible = true
	elif dash_timer < dash_duration:
		player.is_invincible = false
		
		# Lock horizontal input direction during recovery phase
		var input_dir := Input.get_axis("move_left", "move_right")
		var target_speed := 0.0
		if sign(input_dir) == sign(dash_direction.x):
			target_speed = dash_direction.x * player.SPEED
			
		var recovery_time_passed := dash_timer - dash_active_duration
		var total_recovery_time := dash_duration - dash_active_duration
		var t := recovery_time_passed / total_recovery_time
		
		player.velocity.x = lerp(dash_direction.x * speed, target_speed, t)
		
		if not player.is_on_floor():
			player.velocity.y += player.gravity * delta
	else:
		player.is_invincible = false
		player.current_state = Player.State.MOVE
		
	player.move_and_slide()

func interrupt() -> void:
	if player.current_state == Player.State.DASH:
		player.is_invincible = false
		player.current_state = Player.State.MOVE

func reset() -> void:
	dash_cooldown_timer = 0.0
	extra_dash_used = false

func upgrade_cooldown() -> void:
	dash_cooldown = dash_cooldown / 2.0

