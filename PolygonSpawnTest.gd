extends Node2D

var noise = FastNoiseLite.new()

func _ready():
	noise.set_seed(randi()) # Random seed
	var polygons = []

	# Define your area size (adjust as needed)
	var width = get_viewport_rect().size.x
	var height = get_viewport_rect().size.y
	
	print(str(width) + " " + str(height))

	# Set noise parameters
	noise.set_noise_type(FastNoiseLite.TYPE_SIMPLEX)

	# Find seed points and perform flood fill
	for x in range(width):
		for y in range(height):
			var noise_value = noise.get_noise_2d(x, y)
			if noise_value >= 0.9:
				var polygon_points = flood_fill(x, y, width, height)
				if polygon_points.size() > 0:
					var polygon = Polygon2D.new()
					polygon.polygon = polygon_points
					polygons.append(polygon)

	# Add polygons to the scene
	for poly in polygons:
		add_child(poly)

# Flood-fill algorithm to find connected regions of high noise values
func flood_fill(x, y, width, height):
	var visited = []
	var stack = []
	stack.append(Vector2(x, y))

	while stack.size() > 0:
		var current = stack.pop_back()
		var cx = int(current.x)
		var cy = int(current.y)

		if cx < 0 or cx >= width or cy < 0 or cy >= height:
			continue

		if Vector2(cx, cy) in visited:
			continue

		visited.append(Vector2(cx, cy))

		var noise_value = noise.get_noise_2d(cx, cy)
		if abs(noise_value) >= 0.9:
			stack.append(Vector2(cx - 1, cy))
			stack.append(Vector2(cx + 1, cy))
			stack.append(Vector2(cx, cy - 1))
			stack.append(Vector2(cx, cy + 1))

	var points = []
	for coord in visited:
		points.append(Vector2(coord[0], coord[1]))

	return points
