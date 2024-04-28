extends Node2D

const TILE_SIZE = 4
const MIN_POLYGON_SIZE = 20  # Adjust as needed
const EPSILON = 0.000001


@onready var tilemap := $TileMap
var oil_pocket_node = preload("res://oil_pocket.tscn")
var width := 1152/4
var height := 448/4
var in_seed := "eoghan"
var osn := FastNoiseLite.new()

func _ready() -> void:
	osn.set_noise_type(FastNoiseLite.TYPE_SIMPLEX)
	randomize()
	if in_seed:
		osn.seed = hash(in_seed)
		print(hash(in_seed))
	else:
		osn.seed = randi()
	generate_map()
	
	var polygons = []
	var colpolygons = []
	
	var visited = []
	for x in range(width):
		var row = []
		for y in range(height):
			row.append(false)
		visited.append(row)
	
	# Find connected regions of type 1,0 tiles and create polygon areas around them
	for x in range(width):
		for y in range(height):
			if tilemap.get_cell_atlas_coords(0, Vector2(x, y)) == Vector2i(1, 0) and !visited[x][y]:
				var polygon_points = flood_fill(x, y, visited)
				if polygon_points.size() >= MIN_POLYGON_SIZE:
					# Find convex hull of the points
					var convex_hull = find_convex_hull(polygon_points)
					var polygon_area = Polygon2D.new()
					var col_polygon_area = CollisionPolygon2D.new()
					
					# Map the convex hull points to world coordinates
					var world_points = []
					for point in convex_hull:
						world_points.append(point * TILE_SIZE)
					polygon_area.polygon = world_points
					col_polygon_area.polygon = world_points
					polygons.append(polygon_area)
					colpolygons.append(col_polygon_area)
	
	# Add polygon areas to the scene
	var filtered_polygons = filter_degenerate_polygons(polygons)
	var filtered_col_polygons = filter_degenerate_polygons(colpolygons)
	print(filtered_polygons.size())
	if filtered_col_polygons.size() == filtered_polygons.size():
		for i in filtered_col_polygons.size():
			var curpolygon = filtered_polygons[i]
			var curcolpolygon = filtered_col_polygons[i]
			var oil_pocket = oil_pocket_node.instantiate()
			oil_pocket.setup(curpolygon, curcolpolygon)
			add_child(oil_pocket)
	else:
		print("Uh oh")

func generate_map() -> void:
	for x in range(width):
		for y in range(height):
			var rand = floor((abs(osn.get_noise_2d(x, y))) * 2)
			tilemap.set_cell(0, Vector2(x, y), 10, Vector2(rand, 0))
	pass

# Flood-fill algorithm to find connected regions of type 1,0 tiles
func flood_fill(start_x, start_y, visited):
	var outermost_points = []
	var stack = []
	stack.append(Vector2(start_x, start_y))
	visited[start_x][start_y] = true
	
	while stack.size() > 0:
		var current = stack.pop_back()
		var cx = int(current.x)
		var cy = int(current.y)
		
		# Check and add neighboring tiles
		var neighbors = tilemap.get_surrounding_cells(Vector2(cx, cy))
		
		var is_outermost = false
		for neighbor in neighbors:
			var nx = int(neighbor.x)
			var ny = int(neighbor.y)
			if nx >= 0 and nx < width and ny >= 0 and ny < height and tilemap.get_cell_atlas_coords(0, Vector2(nx, ny)) != Vector2i(1, 0):
				is_outermost = true
				break
		
		if is_outermost:
			outermost_points.append(Vector2(cx, cy))
		
		for neighbor in neighbors:
			var nx = int(neighbor.x)
			var ny = int(neighbor.y)
			if nx >= 0 and nx < width and ny >= 0 and ny < height and tilemap.get_cell_atlas_coords(0, Vector2(nx, ny)) == Vector2i(1, 0) and !visited[nx][ny]:
				stack.append(Vector2(nx, ny))
				visited[nx][ny] = true
	
	return outermost_points

# Function to find the convex hull of a set of points
func find_convex_hull(points):
	if points.size() <= 3:
		return points
	
	var hull = []
	
	# Find the leftmost point
	var start_point = points[0]
	for point in points:
		if point.x < start_point.x or (point.x == start_point.x and point.y < start_point.y):
			start_point = point
	
	var current_point = points[1]
	var next_point = Vector2.ZERO
	while current_point != start_point:
		hull.append(current_point)
		next_point = points[0]
		
		for point in points:
			var orientation = orientation(current_point, next_point, point)
			if next_point == current_point or orientation == 1 or (orientation == 0 and distance_squared(current_point, point) > distance_squared(current_point, next_point)):
				next_point = point
		
		current_point = next_point
	
	# Check if the hull points are ordered clockwise
	if is_clockwise(hull):
		# If clockwise, reverse the hull points
		hull.reverse()
	
	return hull

# Function to check if the points are ordered clockwise
func is_clockwise(points):
	var sum = 0
	for i in range(points.size()):
		var current = points[i]
		var next = points[(i + 1) % points.size()]
		sum += (next.x - current.x) * (next.y + current.y)
	return sum < 0


# Function to calculate orientation of three points
func orientation(p1, p2, p3):
	var val = (p2.y - p1.y) * (p3.x - p2.x) - (p2.x - p1.x) * (p3.y - p2.y)
	if val == 0:
		return 0 # Collinear
	return 1 if val > 0 else 2 # Clockwise or Counterclockwise

# Function to calculate squared distance between two points
func distance_squared(p1, p2):
	return (p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y)

func filter_degenerate_polygons(polygons):
	var filtered_polygons = []
	for polygon in polygons:
		if is_degenerate(polygon):
			continue  # Skip degenerate polygons
		filtered_polygons.append(polygon)
	return filtered_polygons

func is_degenerate(polygon):
	# Check if any three consecutive points are collinear or coincident
	var points = polygon.get_polygon()
	# Check if any three consecutive points are collinear or coincident
	for i in range(points.size() - 2):
		var p1 = points[i]
		var p2 = points[i + 1]
		var p3 = points[i + 2]
		if are_collinear(p1, p2, p3) or p1 == p2 or p2 == p3 or p3 == p1:
			return true
	var polygon_area = calculate_polygon_area(polygon)
	if polygon_area < EPSILON:
		return true
	return false

func are_collinear(p1, p2, p3):
	return abs((p2.y - p1.y) * (p3.x - p1.x) - (p3.y - p1.y) * (p2.x - p1.x)) < EPSILON

func calculate_polygon_area(polygon_node):
	var points = polygon_node.polygon
	var area = 0.0
	var j = points.size() - 1

	for i in range(points.size()):
		area += (points[j].x + points[i].x) * (points[j].y - points[i].y)
		j = i

	return abs(area / 2.0)

func calculate_centre(polygon):
	var points = polygon.get_polygon()
	var center = Vector2.ZERO
	
	# Calculate the sum of all vertices
	for point in points:
		center += point
	
	# Calculate the average position
	center /= points.size()
	
	return center

#########################################
#           Game Control                #
#########################################

func _process(delta):
	match $Timer.time_left:
		var x when x <= 31:
			$CanvasLayer/Calendar.set_text("Dec")
		var x when x <= 61:
			$CanvasLayer/Calendar.set_text("Nov")
		var x when x <= 92:
			$CanvasLayer/Calendar.set_text("Oct")
		var x when x <= 122:
			$CanvasLayer/Calendar.set_text("Sep")
		var x when x <= 153:
			$CanvasLayer/Calendar.set_text("Aug")
		var x when x <= 184:
			$CanvasLayer/Calendar.set_text("Jul")
		var x when x <= 214:
			$CanvasLayer/Calendar.set_text("Jun")
		var x when x <= 245:
			$CanvasLayer/Calendar.set_text("May")
		var x when x <= 275:
			$CanvasLayer/Calendar.set_text("Apr")
		var x when x <= 306:
			$CanvasLayer/Calendar.set_text("Mar")
		var x when x <= 334:
			$CanvasLayer/Calendar.set_text("Feb")
		var x when x <= 365:
			$CanvasLayer/Calendar.set_text("Jan")


func _on_timer_timeout():
	print("game over")
	get_tree().paused = true
