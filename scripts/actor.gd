class_name Actor
extends CharacterBody2D

# Shared entity properties (Player & mobile enemies)
@export_group("Health & Physics")
@export var max_health: int = 100
@onready var current_health: int = max_health
@export var friction: float = 1200.0

@export_group("Knockback Settings")
@export var default_knockback_force: float = 250.0
@export var knockback_duration: float = 0.25
@export var slash_from_above_threshold: float = 12.0
@export var slash_from_above_upward_velocity: float = -180.0

# Default project gravity
var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))

# Knockback recovery countdown
var knockback_timer: float = 0.0

# Shared actor signals
signal health_changed(new_health: int)
signal actor_died

# Standard damage logic
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if current_health <= 0:
		return
		
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	
	# Apply knockback if survival condition is met
	if source_position != Vector2.ZERO and current_health > 0:
		apply_knockback(source_position, default_knockback_force)
		
	if current_health <= 0:
		die()

# Standard knockback logic
func apply_knockback(source_position: Vector2, force: float = 250.0) -> void:
	# Horizontal direction away from source
	var push_dir := 1.0 if global_position.x > source_position.x else -1.0
	velocity.x = push_dir * force
	
	# Only keep Y bounce if slashed from above (source is above this actor)
	var is_slashed_from_above := source_position.y < global_position.y - slash_from_above_threshold
	if is_slashed_from_above:
		velocity.y = slash_from_above_upward_velocity
	else:
		velocity.y = 0.0
		
	knockback_timer = knockback_duration # Input block duration (seconds)

# Death callback (must be overridden by subclasses)
func die() -> void:
	actor_died.emit()
