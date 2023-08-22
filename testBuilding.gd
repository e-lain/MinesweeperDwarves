extends Node2D

const TILE_SIZE = 64

var placed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _process(delta):
	var mouse = get_parent().get_local_mouse_position()
	var snapped = Vector2(snapped(mouse.x-TILE_SIZE/2, TILE_SIZE), snapped(mouse.y-TILE_SIZE/2, TILE_SIZE))
	position = snapped
