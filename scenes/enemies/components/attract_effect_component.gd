class_name AttractEffectComponent
extends Node

@export var duration: float = 5.0
@export var speed_multiplier: float = 0.5

var timer: float = 0.0
var original_modulate: Color = Color.WHITE
var enemy_ref: GrabEnemy = null
var previous_state: int = 0

func _ready() -> void:
	enemy_ref = get_parent() as GrabEnemy
	if not enemy_ref:
		queue_free()
		return
		
	# Store previous state and original modulate
	previous_state = enemy_ref.current_state
	if enemy_ref.has_node("Sprite2D"):
		original_modulate = enemy_ref.get_node("Sprite2D").modulate
		# Set neon pink/purple color modulation
		enemy_ref.get_node("Sprite2D").modulate = Color(1.5, 0.5, 1.0, 1.0)
		
	# Transition enemy state to ATTRACTED
	enemy_ref.current_state = GrabEnemy.State.ATTRACTED
	timer = duration

func _physics_process(delta: float) -> void:
	if not is_instance_valid(enemy_ref) or not enemy_ref.is_alive():
		queue_free()
		return
		
	timer -= delta
	if timer <= 0.0:
		remove_effect()

func refresh() -> void:
	timer = duration

func remove_effect() -> void:
	if is_instance_valid(enemy_ref) and enemy_ref.current_state != GrabEnemy.State.DEAD:
		# Restore state and modulate if not dead
		enemy_ref.current_state = previous_state if previous_state != GrabEnemy.State.DEAD else GrabEnemy.State.PATROL
		if enemy_ref.has_node("Sprite2D"):
			enemy_ref.get_node("Sprite2D").modulate = original_modulate
			
	queue_free()

func _exit_tree() -> void:
	# Fallback cleanup
	if is_instance_valid(enemy_ref) and enemy_ref.current_state == GrabEnemy.State.ATTRACTED:
		enemy_ref.current_state = GrabEnemy.State.PATROL
		if enemy_ref.has_node("Sprite2D"):
			enemy_ref.get_node("Sprite2D").modulate = original_modulate
