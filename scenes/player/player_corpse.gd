class_name PlayerCorpse
extends Actor

func _ready() -> void:
	add_to_group("player_corpse")
	current_health = max_health
	if has_node("Sprite2D"):
		# Set modulate to semi-transparent ghostly blue/gray
		$Sprite2D.modulate = Color(0.35, 0.65, 0.95, 0.6)

func _physics_process(delta: float) -> void:
	# Fall with gravity if spawned in mid-air
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	move_and_slide()

func die() -> void:
	# Spawn shard on destruction
	_spawn_shard()
	print("[CORPSE] Player corpse destroyed! Spawning retrieve shard.")
	queue_free()

func _spawn_shard() -> void:
	var shard_scene = load("res://scenes/player/player_shard.tscn")
	if shard_scene:
		var shard = shard_scene.instantiate()
		shard.global_position = global_position
		get_parent().call_deferred("add_child", shard)
