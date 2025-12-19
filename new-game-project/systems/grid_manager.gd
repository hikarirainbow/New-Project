class_name GridManager
extends Object

static var tile_map: TileMapLayer
static var astar: AStarGrid2D

static func setup(map: TileMapLayer) -> void:
	tile_map = map
	astar = AStarGrid2D.new()
	astar.cell_size = Vector2(1, 1) # Assuming 1 unit = 1 tile logic or adjust to pixel size
	# Initialize AStar region/rect if needed, or update dynamically
