class_name Actor
extends CharacterBody2D

# Shared entity properties (Player & mobile enemies)
@export var max_health: int = 100
@onready var current_health: int = max_health

# Default project gravity
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Knockback recovery countdown
var knockback_timer: float = 0.0

# Deceleration friction coefficient for stop/knockback states
@export var friction: float = 1200.0

# Shared actor signals
signal health_changed(new_health)
signal actor_died

# Standard damage logic
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO):
	if current_health <= 0:
		return
		
	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health)
	
	# Apply knockback if survival condition is met
	if source_position != Vector2.ZERO and current_health > 0:
		apply_knockback(source_position)
		
	if current_health <= 0:
		die()

# Standard knockback logic
func apply_knockback(source_position: Vector2, force: float = 250.0):
	# Horizontal direction away from source
	var push_dir = 1.0 if global_position.x > source_position.x else -1.0
	velocity.x = push_dir * force
	
	# Only keep Y bounce if slashed from above (source is above this actor)
	var is_slashed_from_above = source_position.y < global_position.y - 12.0
	if is_slashed_from_above:
		velocity.y = -180.0
	else:
		velocity.y = 0.0
		
	knockback_timer = 0.25 # Input block duration (seconds)

# Death callback (must be overridden by subclasses)
func die():
	emit_signal("actor_died")
