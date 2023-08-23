extends Node2D

var Board = preload("res://board.tscn")

var population = 3
var stone = 0
var b

signal queue_building(building_name)

# Called when the node enters the scene tree for the first time.
func _ready():
	# place board in center with correct offset accounting for tile size and board size
	b = Board.instantiate()
	var center = get_viewport_rect().size/2
	var offset = Vector2(center.x-(b.rows * b.TILE_SIZE/2), center.y-(b.columns * b.TILE_SIZE/2))
	b.position = offset
	add_child(b)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_node("UI/Resources/Population").text = "Population: %d" % [population]
	get_node("UI/Resources/Stone").text = "Stone: %d" % [stone]

func build(building_name):
	print("func build, building_name: ", building_name)
	if building_name == "test":
		# Signal the board to start building placement for test building
		queue_building.emit("test")
	if building_name == "staircase":
		queue_building.emit("staircase")

func next_level():
	print("MAIN SCENE RECEIVED NEXT LEVEL CALL")

func _on_end_level_btn_pressed():
	if b.build_mode == false:
		b.enter_build_mode()
		print("MANUALLY ENTERING BUILD MODE")
	else:
		print("ALREADY IN BUILD MODE")
