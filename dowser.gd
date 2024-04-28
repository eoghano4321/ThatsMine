extends Area2D

#@onready var col = $CollisionShape2D
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position = get_global_mouse_position()
	
	var colliders = get_overlapping_areas()
	var highest_col = check_collisions(colliders)
	match highest_col:
		1:
			print("pocket")
		2:
			print("inner")
		3:
			print("outer")

func check_collisions(colliders):
	for col in colliders:
		if col.is_in_group("pocket"):
			return 1
	for col in colliders:
		print(col)
		if col.is_in_group("inner_ring"):
			return 2
	for col in colliders:
		print(col)
		if col.is_in_group("outer_ring"):
			return 3
	return 0
