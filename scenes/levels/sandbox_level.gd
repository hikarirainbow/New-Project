extends Node2D

const MapTile = preload("res://scenes/levels/map_tile.gd")
const GrabEnemyScene = preload("res://scenes/enemies/grab_enemy.tscn")

const TILE  = 32
const COLS  = 60   # 1920 px wide
const ROWS  = 20   # 640 px tall

var rng := RandomNumberGenerator.new()
var solid_cells := {}

func _ready() -> void:
	rng.randomize()
	_setup_darkness()
	_build_map()
	_setup_camera_limits()

func _physics_process(_delta: float) -> void:
	_maintain_enemies()

# ── AMBIENT DARKNESS ─────────────────────────────────────────────────────────
func _setup_darkness() -> void:
	var canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = Color(0.08, 0.08, 0.12) # Tối đen với ánh xanh dương nhẹ
	add_child(canvas_modulate)

# ── TILE PLACEMENT ──────────────────────────────────────────────────────────
func _place(col: int, row: int) -> void:
	var t      = MapTile.new()
	t.position = Vector2(col * TILE + TILE * 0.5, row * TILE + TILE * 0.5)
	add_child(t)
	solid_cells[Vector2i(col, row)] = true

# ── MAP GENERATION ───────────────────────────────────────────────────────────
func _build_map() -> void:
	# Ceiling (row 0)
	for c in range(COLS):
		_place(c, 0)

	# Floor (row 19)
	for c in range(COLS):
		_place(c, ROWS - 1)

	# Left wall (col 0, rows 1-18)
	for r in range(1, ROWS - 1):
		_place(0, r)

	# Right wall (col 59, rows 1-18)
	for r in range(1, ROWS - 1):
		_place(COLS - 1, r)

	# Random platform layers at rows 16, 13, 10, 7
	# (96 px spacing = 3 tiles — reachable with 103 px max jump)
	for row in [16, 13, 10, 7]:
		_build_platform_row(row)

func _build_platform_row(row: int) -> void:
	var target_platforms := rng.randi_range(4, 6)
	var used             := {}    # col → true
	var placed           := 0
	var tries            := 0

	while placed < target_platforms and tries < 40:
		tries += 1
		var start_col  = rng.randi_range(2, COLS - 5)
		var length     = rng.randi_range(2, 4)
		var end_col    = min(start_col + length - 1, COLS - 2)

		# Need at least 1 empty column gap between platforms
		var clear := true
		for c in range(start_col - 1, end_col + 2):
			if used.has(c):
				clear = false
				break

		if clear:
			for c in range(start_col, end_col + 1):
				used[c] = true
				_place(c, row)
			placed += 1

# ── ENEMY SPAWNER ────────────────────────────────────────────────────────────
func _get_valid_spawn_position() -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	var player_pos = player.global_position if player else Vector2.ZERO
	
	var candidates := []
	for cell in solid_cells.keys():
		var col = cell.x
		var row = cell.y
		
		# Cần một ô solid mà 2 ô phía trên nó trống để spawn quái
		var cell_above = Vector2i(col, row - 1)
		var cell_two_above = Vector2i(col, row - 2)
		
		if not solid_cells.has(cell_above) and not solid_cells.has(cell_two_above):
			# Tránh các hàng và cột sát viền ngoài cùng
			if col > 0 and col < COLS - 1 and row > 0 and row < ROWS - 1:
				var spawn_pos = Vector2(col * TILE + TILE * 0.5, (row - 1) * TILE + TILE * 0.5)
				
				# Tránh spawn quá gần người chơi (khoảng cách tối thiểu 300px)
				if player_pos == Vector2.ZERO or spawn_pos.distance_to(player_pos) > 300.0:
					candidates.append(spawn_pos)
					
	if candidates.size() > 0:
		return candidates[rng.randi_range(0, candidates.size() - 1)]
	
	# Vị trí mặc định dự phòng
	return Vector2(300, 300)

func _maintain_enemies() -> void:
	var alive_count = 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("is_alive") and enemy.is_alive():
			alive_count += 1
			
	while alive_count < 5:
		var spawn_pos = _get_valid_spawn_position()
		var new_enemy = GrabEnemyScene.instantiate()
		new_enemy.position = spawn_pos
		add_child(new_enemy)
		alive_count += 1

# ── CAMERA LIMITS ────────────────────────────────────────────────────────────
func _setup_camera_limits() -> void:
	await get_tree().process_frame   # wait for player to enter tree
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if not cam:
		return
	cam.limit_left   = 0
	cam.limit_top    = 0
	cam.limit_right  = COLS * TILE   # 1920
	cam.limit_bottom = ROWS * TILE   # 640
