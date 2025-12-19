extends Node2D
class_name GameManager

# --- SINGLETON PATTERN (Optional, but using Group is safer here) ---
# --- PATHFINDING ---
var astar: AStar2D
var tile_map: TileMapLayer
var used_rect: Rect2i

# --- TASK SYSTEM ---
# Danh sách các ô cần đào: { Vector2i: true }
var dig_tasks: Dictionary = {} 

func _ready() -> void:
	astar = AStar2D.new()
	# Tìm TileMap trong group terrain
	tile_map = get_tree().get_first_node_in_group("terrain")
	
	# Đợi map load xong rồi build graph
	await get_tree().process_frame
	build_navigation_graph()

# --- A* GRAPH BUILDING ---
func build_navigation_graph() -> void:
	if not tile_map: return
	
	astar.clear()
	used_rect = tile_map.get_used_rect()
	
	# 1. Add Points (Nodes)
	# Quét rộng hơn một chút để bao gồm cả vùng biên
	for x in range(used_rect.position.x - 5, used_rect.end.x + 5):
		for y in range(used_rect.position.y - 5, used_rect.end.y + 5):
			var pos = Vector2i(x, y)
			var id = _get_point_id(pos)
			
			# Logic: Nếu là Air -> Walkable
			# Nếu là Solid -> Mineable (Cost cao)
			if not _is_solid(pos):
				astar.add_point(id, Vector2(pos))
			else:
				# Vẫn add point cho block, nhưng weight cao (để Unit biết đường đào xuyên tường nếu bí)
				astar.add_point(id, Vector2(pos), 10.0) 

	# 2. Connect Points (Edges)
	for x in range(used_rect.position.x - 5, used_rect.end.x + 5):
		for y in range(used_rect.position.y - 5, used_rect.end.y + 5):
			var pos = Vector2i(x, y)
			var id = _get_point_id(pos)
			
			if not astar.has_point(id): continue
			
			# Kết nối các ô xung quanh
			_connect_neighbor(pos, Vector2i(1, 0))  # Phải
			_connect_neighbor(pos, Vector2i(-1, 0)) # Trái
			_connect_neighbor(pos, Vector2i(0, 1))  # Dưới (Rơi)
			_connect_neighbor(pos, Vector2i(0, -1)) # Trên (Nhảy/Leo)
			
			# Kết nối chéo (Nhảy qua hố hoặc leo dốc)
			_connect_neighbor(pos, Vector2i(1, -1))
			_connect_neighbor(pos, Vector2i(-1, -1))
			_connect_neighbor(pos, Vector2i(1, 1))
			_connect_neighbor(pos, Vector2i(-1, 1))

func _connect_neighbor(pos: Vector2i, offset: Vector2i) -> void:
	var neighbor = pos + offset
	var neighbor_id = _get_point_id(neighbor)
	
	if astar.has_point(neighbor_id):
		# TODO: Thêm logic kiểm tra xem có nhảy được không (Platformer physics)
		# Hiện tại nối hết để Unit đi được đã, sẽ tinh chỉnh sau
		astar.connect_points(_get_point_id(pos), neighbor_id, false) # False = 1 chiều (quan trọng cho trọng lực)
		
		# Cho phép đi 2 chiều nếu là đi ngang
		if offset.y == 0:
			astar.connect_points(neighbor_id, _get_point_id(pos), false)

func _get_point_id(pos: Vector2i) -> int:
	# Cantor pairing function hoặc map coordinate sang int
	# Đơn giản nhất: dùng tọa độ tương đối với rect
	var w = used_rect.size.x + 10
	return (pos.y - used_rect.position.y) * w + (pos.x - used_rect.position.x)

func _is_solid(pos: Vector2i) -> bool:
	return tile_map.get_cell_source_id(pos) != -1

# --- PUBLIC API ---
func get_path_cells(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start = tile_map.local_to_map(tile_map.to_local(from))
	var end = tile_map.local_to_map(tile_map.to_local(to))
	
	var start_id = _get_point_id(start)
	var end_id = _get_point_id(end)
	
	if not astar.has_point(start_id) or not astar.has_point(end_id):
		return PackedVector2Array()
		
	var path_ids = astar.get_point_path(start_id, end_id)
	
	# Convert về World Position (Center của tile)
	var world_path = PackedVector2Array()
	for p in path_ids:
		world_path.append(tile_map.to_global(tile_map.map_to_local(Vector2i(p.x, p.y))))
	
	return world_path

func add_dig_task(tile_pos: Vector2i) -> void:
	if _is_solid(tile_pos):
		dig_tasks[tile_pos] = true
		# TODO: Visual feedback (Red border)
		print("Task added: ", tile_pos)
		
		# Sau khi thêm task, rebuild graph nếu cần (để unit biết đường đi qua - logic phức tạp, tạm bỏ qua)
		
func remove_dig_task(tile_pos: Vector2i) -> void:
	dig_tasks.erase(tile_pos)
	# Rebuild graph cục bộ (đục lỗ tường)
	# Tạm thời gọi rebuild toàn bộ cho dễ
	build_navigation_graph()

func get_nearest_dig_task(unit_pos: Vector2) -> Vector2i:
	# Tìm task gần nhất (đơn giản)
	var min_dist = INF
	var nearest = Vector2i.ZERO
	var found = false
	
	for task in dig_tasks.keys():
		var dist = unit_pos.distance_to(tile_map.map_to_local(task))
		if dist < min_dist:
			min_dist = dist
			nearest = task
			found = true
	
	return nearest if found else Vector2i.ZERO
