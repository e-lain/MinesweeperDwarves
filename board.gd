extends Node2D

var Tile = preload("res://Tile.tscn")
var TestBuilding = preload("res://testBuilding.tscn")

const TILE_SIZE = 64

var build_mode: bool = false
var placing: bool = false

var row = 3
var col = 3
var bomb_count = 1
var bombs_found = 0
var tiles_uncovered = 0
var total_tiles = row*col
var tiles

var population = 10
var food = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	get_parent().queue_building.connect(_on_building_queue)
	randomize()
	for r in row:
		for c in col:
			var t = Tile.instantiate()
			t.position = Vector2(r, c) * TILE_SIZE
			add_child(t)
	tiles = get_children()
	set_bombs()
	
func set_bombs():
	var n = 0
	while n < bomb_count:
		var tile = tiles[randi() % len(tiles)]
		if tile.is_bomb == false:
			tile.set_bomb()
			n += 1

func _process(delta):
	if tiles_uncovered == total_tiles - bomb_count:
		build_mode = true
		bombs_found = 0
		tiles_uncovered = 0
		print("TODO: LEVEL WIN! BUILD MODE ENGAGED")
	get_parent().population = population
	get_parent().food = food
	
func _on_building_queue(building_name):
	if build_mode and !placing:
		placing = true
		var building
		if building_name == "test":
			print("SIGNAL RECEIVED TO BUILD TEST BUILDING")
			building = TestBuilding.instantiate()
		add_child(building)
