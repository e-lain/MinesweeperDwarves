extends Node2D

@onready var depth_label = $CanvasLayer/UI/Depth
@onready var population_label = $CanvasLayer/UI/Resources/PopulationBox/Population
@onready var stone_label =$CanvasLayer/UI/Resources/StoneBox/Stone

var Board = preload("res://board.tscn")

var build_mode: bool = false

var depth = 0
var population = 3
var stone = 0

var boards = []

signal queue_building(building_type: BuildingData.Type)

func generate_board(difficulty: int):
	var b = Board.instantiate()
	add_child(b)
	
	if difficulty == 0:
		b.init_board(6,6,4)
	elif difficulty == 1:
		b.init_board(7,7,5)
	elif difficulty == 2:
		b.init_board(8,8,7)
	elif difficulty == 3:
		b.init_board(9,9,9)
	else:
		b.init_board(10,10,10)
		
	var center = get_viewport_rect().size/2
	var offset = Vector2(center.x-(b.rows * b.TILE_SIZE/2), center.y-(b.columns * b.TILE_SIZE/2))
	b.position = offset
	b.create_grid_lines()
	boards.push_back(b)

# Called when the node enters the scene tree for the first time.
func _ready():
	# place board in center with correct offset accounting for tile size and board size
	generate_board(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	population_label.text = "x %d" % [population]
	stone_label.text = "x %d" % [stone]
	depth_label.text = "Depth: %d" % [depth + 1]

func build(type: BuildingData.Type):
	print("func build, building_name: ", type)
	queue_building.emit(type)

func next_level():
	print("MAIN SCENE RECEIVED NEXT LEVEL CALL")
	depth += 1
	generate_board(depth)

func _on_end_level_btn_pressed():
	if boards[len(boards)-1].build_mode == false:
		boards[len(boards)-1].enter_build_mode()
		print("MANUALLY ENTERING BUILD MODE")
	else:
		print("ALREADY IN BUILD MODE")
