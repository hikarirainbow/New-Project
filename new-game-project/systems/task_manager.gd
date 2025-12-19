class_name TaskManager
extends Object

static var tasks: Array[Vector2i] = []

static func add_task(coord: Vector2i) -> void:
	if not coord in tasks:
		tasks.append(coord)

static func get_nearest_task(unit_pos: Vector2) -> Vector2i:
	if tasks.is_empty():
		return Vector2i.ZERO # Return ZERO or check for validity elsewhere
	
	# Simple linear search for nearest (Optimize later if needed)
	var nearest: Vector2i = tasks[0]
	var min_dist = unit_pos.distance_squared_to(Vector2(nearest))
	
	for t in tasks:
		var d = unit_pos.distance_squared_to(Vector2(t))
		if d < min_dist:
			min_dist = d
			nearest = t
			
	return nearest

static func complete_task(coord: Vector2i) -> void:
	tasks.erase(coord)
