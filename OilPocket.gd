extends Node2D

@onready var timer = $Timer
var oil_shader = preload("res://OilPocket.gdshader")
var harvesting = false
var timer_length = 0
var has_oil = true

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		harvest()
	if harvesting:
		$Pocket/PocketMesh.material.set("shader_parameter/fullness", (timer.get_time_left()/timer_length))



func harvest():
	timer_length = floor(get_polygon_height($Pocket/PocketMesh))+2
	print(timer_length)
	timer.set_wait_time(timer_length)
	timer.start()
	harvesting = true

func setup(polygon, colpolygon):
	$Pocket/PocketMesh.polygon = polygon.get_polygon()
	$Pocket/PocketCol.polygon = colpolygon.get_polygon()
	
	var circle = CircleShape2D.new()
	var circle2 = CircleShape2D.new()
	
	var pocket_area = calculate_polygon_area(polygon)
	
	circle.radius = sqrt(pocket_area/3.14)*2
	$InnerRing/InnerDowseRing.set_shape(circle)
	$InnerRing/InnerDowseRing.set_global_position(calculate_centre(polygon))
	circle2.radius = sqrt(pocket_area/3.14)*3
	$OuterRing/OuterDowseRing.set_shape(circle2)
	$OuterRing/OuterDowseRing.set_global_position(calculate_centre(polygon))
	
	var oil_material = ShaderMaterial.new()
	oil_material.set_shader(oil_shader)
	$Pocket/PocketMesh.set_material(oil_material)
	$Pocket/PocketMesh.material.set("shader_parameter/liqCol", Color(0.0, 0.0, 0.1, 1.0))
	$Pocket/PocketMesh.material.set("shader_parameter/empCol", Color(1.0, 0.0, 0.0, 1.0))
	$Pocket/PocketMesh.material.set("shader_parameter/fullness", 1.0)
	var minY = calculate_centre(polygon).y-(get_polygon_height(polygon)/2)-5
	var maxY = calculate_centre(polygon).y+(get_polygon_height(polygon)/2)+5
	$Pocket/PocketMesh.material.set("shader_parameter/minY", minY)
	$Pocket/PocketMesh.material.set("shader_parameter/maxY", maxY)

func calculate_polygon_area(polygon_node):
	var points = polygon_node.polygon
	var area = 0.0
	var j = points.size() - 1

	for i in range(points.size()):
		area += (points[j].x + points[i].x) * (points[j].y - points[i].y)
		j = i

	return abs(area / 2.0)

func get_polygon_height(polygon_node):
	# Get the vertices of the polygon
	var vertices = polygon_node.polygon

	# Initialize min and max y-coordinates
	var min_y = vertices[0].y
	var max_y = vertices[0].y

	# Find min and max y-coordinates
	for vertex in vertices:
		min_y = min(min_y, vertex.y)
		max_y = max(max_y, vertex.y)
	
	# Calculate height
	var height = max_y - min_y
	return height


func calculate_centre(polygon):
	var points = polygon.get_polygon()
	var center = Vector2.ZERO
	
	# Calculate the sum of all vertices
	for point in points:
		center += point
	
	# Calculate the average position
	center /= points.size()
	
	# Print the center of the polygon
	return center


func _on_timer_timeout():
	harvesting = false
	has_oil = false
	$Pocket/PocketMesh.material.set("shader_parameter/fullness", 0.0)
	$Pocket/PocketMesh.material.set("shader_parameter/empCol", Color(1.0, 1.0, 0.0, 1.0))
