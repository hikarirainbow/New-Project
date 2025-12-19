class_name MapGenerator
extends TileMapLayer

# --- CẤU HÌNH ---
@export_category("Chunk Settings")
@export var chunk_size: int = 16        
@export var render_distance: int = 8      
@export var unload_distance: int = 12     
@export var chunks_generated_per_frame: int = 1

@export_category("Terrain Settings")
@export var terrain_set_id: int = 0
@export var terrain_id: int = 0
@export var fill_percent: float = 0.50

@export_category("Noise Settings")
@export var noise_seed: int = 1234
@export var noise_frequency: float = 0.05

# --- RESOURCES ---
const UNIT_SCENE = preload("res://entities/mobs/unit.tscn")
const PLAYER_MAIN_SCENE = preload("res://entities/player/player_main.tscn")

# --- BIẾN NỘI BỘ ---
var noise: FastNoiseLite
var loaded_chunks: Dictionary = {} 
var player_main: Node2D 
var game_ui: CanvasLayer

func _ready() -> void:
	await get_tree().process_frame
	
	noise = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = noise_frequency
	
	for x in range(-2, 3):
		for y in range(-2, 3):
			generate_chunk(Vector2i(x, y))
			
	spawn_initial_entities()
	
	# Register with GridManager
	GridManager.setup(self)
	
	game_ui = get_parent().get_node_or_null("GameUI")
	if game_ui:
		game_ui.spawn_requested.connect(spawn_unit_at_camera)
	else:
		push_warning("MapGenerator: Không tìm thấy GameUI!")

func _process(_delta: float) -> void:
	if not player_main: return
	
	var center_pos = local_to_map(player_main.position)
	var current_chunk_x = floor(float(center_pos.x) / chunk_size)
	var current_chunk_y = floor(float(center_pos.y) / chunk_size)
	var current_chunk = Vector2i(current_chunk_x, current_chunk_y)
	
	var generated_count = 0
	for x in range(current_chunk.x - render_distance, current_chunk.x + render_distance + 1):
		for y in range(current_chunk.y - render_distance, current_chunk.y + render_distance + 1):
			var chunk_pos = Vector2i(x, y)
			if not loaded_chunks.has(chunk_pos):
				generate_chunk(chunk_pos)
				generated_count += 1
				if generated_count >= chunks_generated_per_frame:
					break 
		if generated_count >= chunks_generated_per_frame:
			break
			
	if Engine.get_physics_frames() % 10 == 0:
		unload_distant_chunks(current_chunk)

func generate_chunk(chunk_pos: Vector2i) -> void:
	var cells_to_place: Array[Vector2i] = []
	var start_x = chunk_pos.x * chunk_size
	var start_y = chunk_pos.y * chunk_size
	
	for x in range(chunk_size):
		for y in range(chunk_size):
			var global_x = start_x + x
			var global_y = start_y + y
			var noise_val = noise.get_noise_2d(global_x, global_y)
			
			if noise_val > (1.0 - fill_percent * 2.0):
				cells_to_place.append(Vector2i(global_x, global_y))
	
	loaded_chunks[chunk_pos] = true
	if cells_to_place.size() > 0:
		set_cells_terrain_connect(cells_to_place, terrain_set_id, terrain_id, false)

func unload_distant_chunks(current_center_chunk: Vector2i) -> void:
	var chunks_to_remove: Array[Vector2i] = []
	for chunk_pos in loaded_chunks.keys():
		var distance = Vector2(chunk_pos).distance_to(Vector2(current_center_chunk))
		if distance > unload_distance:
			chunks_to_remove.append(chunk_pos)
	for chunk_pos in chunks_to_remove:
		remove_chunk(chunk_pos)

func remove_chunk(chunk_pos: Vector2i) -> void:
	loaded_chunks.erase(chunk_pos)
	var cells_to_remove: Array[Vector2i] = []
	var start_x = chunk_pos.x * chunk_size
	var start_y = chunk_pos.y * chunk_size
	for x in range(chunk_size):
		for y in range(chunk_size):
			cells_to_remove.append(Vector2i(start_x + x, start_y + y))
	
	if cells_to_remove.size() > 0:
		set_cells_terrain_connect(cells_to_remove, 0, -1, false)

func spawn_initial_entities() -> void:
	var spawn_pos = find_safe_spawn_pos(0)
	
	# Chỉ spawn PlayerMain (Camera)
	var pm = PLAYER_MAIN_SCENE.instantiate()
	pm.position = spawn_pos
	add_sibling(pm) 
	player_main = pm
	
	# Đã bỏ spawn Unit ban đầu

func spawn_unit_at_camera() -> void:
	if not player_main: return
	var cam_pos = local_to_map(player_main.position)
	var spawn_pos = find_safe_spawn_pos(cam_pos.x)
	var unit = UNIT_SCENE.instantiate()
	unit.position = spawn_pos
	add_sibling(unit)
	print("Spawned new Unit at: ", spawn_pos)

func find_safe_spawn_pos(x_column: int) -> Vector2:
	for y in range(-100, 100):
		var noise_val = noise.get_noise_2d(x_column, y)
		if noise_val > (1.0 - fill_percent * 2.0):
			return map_to_local(Vector2i(x_column, y - 1))
	return map_to_local(Vector2i(x_column, 0))
