class_name PlayerShard
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Float up and down animation
	var start_y = position.y
	var tween = create_tween().set_loops().set_ignore_time_scale(true)
	tween.tween_property(self, "position:y", start_y - 8.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", start_y, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var player = body as Player
		
		# Recover 50 sanity
		if player.corruption_component:
			player.corruption_component.add_sanity(50.0)
			
		# Restore max health to 100 (standard max health) and clear debuff
		player.remove_debuff()
		
		print("[SHARD] Player retrieved death shard! Max HP restored to 100, Sanity +50.")
		queue_free()
