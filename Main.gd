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
	var offset = Vector2(center.x-(b.rows * b.TILE_SIZE/2), center.y-(b.columns * b.TILE_SIZE/2))
	b.position = offset
	b.go_to_next_level.connect(_on_go_to_next_level)
	add_child(b)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_node("UI/Resources/Population").text = "Population: %d" % [population]
	get_node("UI/Resources/Food").text = "Food: %d" % [food]

func build(building_name):
	print("func build, building_name: ", building_name)
	if building_name == "test":
		# Signal the board to start building placement for test building
		queue_building.emit("test")
	if building_name == "staircase":
		queue_building.emit("staircase")

func _on_go_to_next_level():
	print("MAIN SCENE RECEIVED NEXT LEVEL SIGNAL")

func _on_end_level_btn_pressed():
	if b.build_mode == false:
		b.enter_build_mode()
		print("MANUALLY ENTERING BUILD MODE")
	else:
		print("ALREADY IN BUILD MODE")
