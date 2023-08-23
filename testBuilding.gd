extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
var building_placement_material: ShaderMaterial = preload("res://Shaders/InvalidBuildingPlacement.tres")

const TILE_SIZE = 64

var placed: bool = false
var in_bounds: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _process(delta):
	if !placed:
		var mouse = get_parent().get_local_mouse_position()
		var snapped = Vector2(snapped(mouse.x-TILE_SIZE/2, TILE_SIZE), snapped(mouse.y-TILE_SIZE/2, TILE_SIZE))
		position = snapped
		if position.x <= 0 - TILE_SIZE || position.x >= TILE_SIZE * get_parent().rows || position.y <= 0-TILE_SIZE || position.y >= TILE_SIZE * get_parent().columns:
			self.hide()
			in_bounds = false
		else:
			self.show()
			in_bounds = true
		
		if in_bounds:
			if !can_place():
				sprite.material = building_placement_material
			else:
				sprite.material = null

func _input(event):
	if event is InputEventMouseButton && !placed:
		if event.is_action_pressed("left_click"):
			if can_place() && in_bounds:
				placed = true
				get_parent().placing = false
				return
		if event.is_action_pressed("right_click"):
			get_parent().placing = false
			queue_free()

func can_place():
	return get_parent().can_place_at_position(global_position)
