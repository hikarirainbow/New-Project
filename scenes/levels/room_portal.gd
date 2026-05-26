extends Area2D

# Expose portal configuration in Inspector
@export var portal_id: String = "left" # "left" or "right"
@export var target_room_path: String = "res://scenes/levels/sandbox_level.tscn"
@export var target_portal_id: String = "right" # Entering "left" portal leads to "right" portal in next room

func _ready() -> void:
	add_to_group("portals")
	body_entered.connect(_on_body_entered)
	
	collision_layer = 0
	collision_mask = 2 # Detect Player

	var shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(32, 64)
	shape.shape = rect_shape
	add_child(shape)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Trigger the transition via RoomManager Autoload deferredly using absolute path to avoid compile-time parse errors
		var room_mgr = get_node_or_null("/root/RoomManager")
		if room_mgr:
			room_mgr.call_deferred("transition_to_room", target_room_path, target_portal_id)

func _draw() -> void:
	# Draw the portal as 2 white tiles (32x64px)
	draw_rect(Rect2(-16, -32, 32, 64), Color(1.0, 1.0, 1.0, 1.0))
