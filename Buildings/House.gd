extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
var building_placement_material: ShaderMaterial = preload("res://Shaders/InvalidBuildingPlacement.tres")

const TILE_SIZE = 64

var placed: bool = false
var in_bounds: bool = false
var size: int = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _process(delta):
	if !placed:
		var mouse = get_parent().get_local_mouse_position()
		var snapped = Vector2(snapped(mouse.x-TILE_SIZE/2, TILE_SIZE), snapped(mouse.y-TILE_SIZE/2, TILE_SIZE))
		position = snapped
		# Upper bound x and y are -1 because this is a 2x2 building
		if position.x <= 0 - TILE_SIZE || position.x >= TILE_SIZE * (get_parent().rows-1) || position.y <= 0-TILE_SIZE || position.y >= TILE_SIZE * (get_parent().columns-1):
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

func can_place():
	if get_parent().get_parent().stone - 10 < 0:
		return false
	return get_parent().can_place_at_position(global_position, size)

func _on_control_gui_input(event):
	if event is InputEventMouseButton && !placed:
		if event.is_action_pressed("left_click"):
			if can_place() && in_bounds:
				placed = true
				get_parent().on_building_placed(global_position, size, false)
				get_parent().get_parent().stone -= 10
				get_parent().get_parent().population += 2
				return
		if event.is_action_pressed("right_click"):
			get_parent().placing = false
			queue_free()
