extends Node2D

const MapTile = preload("res://scenes/levels/map_tile.gd")

const TILE  = 64
const COLS  = 20   # 1280 px wide
const ROWS  = 13   # 832 px tall

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_build_map()
	_setup_camera_limits()

# ── TILE PLACEMENT ──────────────────────────────────────────────────────────
func _place(col: int, row: int) -> void:
	var t      = MapTile.new()
	t.position = Vector2(col * TILE + TILE * 0.5, row * TILE + TILE * 0.5)
	add_child(t)

# ── MAP GENERATION ───────────────────────────────────────────────────────────
func _build_map() -> void:
	# Ceiling (row 0)
	for c in range(COLS):
		_place(c, 0)

	# Floor (row 12)
	for c in range(COLS):
		_place(c, ROWS - 1)

	# Left wall (col 0, rows 1-11)
	for r in range(1, ROWS - 1):
		_place(0, r)

	# Right wall (col 19, rows 1-11)
	for r in range(1, ROWS - 1):
		_place(COLS - 1, r)

	# Random platform layers at rows 9, 6, 3
	# (192 px spacing ≈ 3 tiles — reachable with 220 px max jump)
	for row in [9, 6, 3]:
		_build_platform_row(row)

func _build_platform_row(row: int) -> void:
	var target_platforms := rng.randi_range(2, 3)
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
	cam.limit_right  = COLS * TILE   # 1280
	cam.limit_bottom = ROWS * TILE   # 832
