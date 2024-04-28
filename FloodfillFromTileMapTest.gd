extends Node2D

# Define constants for tile types
const TILE_TYPE_EMPTY = 0
const TILE_TYPE_1 = 1
const TILE_TYPE_2 = 2

func _ready():
	var tilemap = $TileMap
	var polygons = []

	# Find connected regions of type 2 tiles and create polygon areas around them
	for x in range(tilemap.get_map_size().x):
		for y in range(tilemap.get_map_size().y):
			if tilemap.get_cell(x, y) == TILE_TYPE_2:
				var polygon_points = flood_fill(x, y, tilemap)
				if polygon_points.size() > 0:
					var polygon_area = Polygon2D.new()
					polygon_area.polygon = polygon_points
					polygons.append(polygon_area)

	# Add polygon areas to the scene
	for polygon in polygons:
		add_child(polygon)

# Flood-fill algorithm to find connected regions of type 2 tiles
func flood_fill(x, y, tilemap):
	var visited = []
	var stack = []
	stack.append(Vector2(x, y))

	while stack.size() > 0:
		var current = stack.pop_back()
		var cx = int(current.x)
		var cy = int(current.y)

		if cx < 0 or cx >= tilemap.get_map_size().x or cy < 0 or cy >= tilemap.get_map_size().y:
			continue

		if Vector2(cx, cy) in visited:
			continue

		visited.append(Vector2(cx, cy))

		if tilemap.get_cell(cx, cy) == TILE_TYPE_2:
			stack.append(Vector2(cx - 1, cy))
			stack.append(Vector2(cx + 1, cy))
			stack.append(Vector2(cx, cy - 1))
			stack.append(Vector2(cx, cy + 1))

	var points = []
	for coord in visited:
		# Convert tile coordinates to world coordinates
		var world_pos = tilemap.map_to_world(Vector2(coord[0], coord[1]))
		# Add the world position to the polygon points
		points.append(world_pos)

	return points
