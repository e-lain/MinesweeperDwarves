extends Node2D

const TILE_SIZE = 32

var row = 8
var col = 8
var bomb_count = 10
var Tile = preload("res://Tile.tscn")
var tiles

# Called when the node enters the scene tree for the first time.
func _ready():
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
