class_name Orc
extends GrabEnemy

func _init() -> void:
	# Default balanced stats for Orc (stronger, larger, faster than Goblin)
	patrol_speed = 80.0
	chase_speed = 120.0
	contact_damage = 30
	chase_radius = 180.0
	sp_gain = 2
	contact_hitbox_size = Vector2(60.0, 90.0)
	key_name_to_drop = "Boss Key"
	attack_cooldown = 2.8
