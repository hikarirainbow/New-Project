extends StaticBody2D

const SIZE = 64.0

func _ready() -> void:
	collision_layer = 1
	collision_mask  = 0

	var shape      = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(SIZE, SIZE)
	shape.shape     = rect_shape
	add_child(shape)

func _draw() -> void:
	var h := SIZE * 0.5
	# Brown earth fill
	draw_rect(Rect2(-h, -h, SIZE, SIZE), Color(0.45, 0.26, 0.08))
	# Black border
	draw_rect(Rect2(-h, -h, SIZE, SIZE), Color(0.05, 0.05, 0.05), false, 1.5)
