extends Node2D

var Board = preload("res://board.tscn")

var population = 0
var food = 0
var b

signal queue_building(building_name)

# Called when the node enters the scene tree for the first time.
func _ready():
	# place board in center with correct offset accounting for tile size and board size
	b = Board.instantiate()
	var center = get_viewport_rect().size/2
	var offset = Vector2(center.x-(b.row * b.TILE_SIZE/2), center.y-(b.col * b.TILE_SIZE/2))
	b.position = offset
	add_child(b)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_node("UI/Resources/Population").text = "Population: %d" % [population]
	get_node("UI/Resources/Food").text = "Food: %d" % [food]


func _on_test_building_clicked(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click"):
			# Signal the board to start building placement for test building
			queue_building.emit("test")

