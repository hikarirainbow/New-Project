extends StaticBody2D

const SIZE = 32.0

func _ready() -> void:
	collision_layer = 1
	collision_mask  = 0

	var shape      = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(SIZE, SIZE)
	shape.shape     = rect_shape
	add_child(shape)

	# Light occluder for dynamic 2D shadows
	var occluder = LightOccluder2D.new()
	var poly = OccluderPolygon2D.new()
	var h := SIZE * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-h, -h),
		Vector2(h, -h),
		Vector2(h, h),
		Vector2(-h, h)
	])
	occluder.occluder = poly
	add_child(occluder)

func _draw() -> void:
	var h := SIZE * 0.5
	# Brown earth fill
	draw_rect(Rect2(-h, -h, SIZE, SIZE), Color(0.45, 0.26, 0.08))
	# Black border
	draw_rect(Rect2(-h, -h, SIZE, SIZE), Color(0.05, 0.05, 0.05), false, 1.5)
