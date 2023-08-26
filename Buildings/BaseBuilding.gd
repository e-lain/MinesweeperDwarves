extends Node2D
class_name BaseBuilding

@export var type: BuildingData.Type
@onready var sprite: Sprite2D = $Sprite2D
var building_placement_material: ShaderMaterial = preload("res://Shaders/InvalidBuildingPlacement.tres")


const TILE_SIZE = 64

var placed: bool = false
var in_bounds: bool = false

var id: int
var size: int

func set_type(value):
	type = value
	size = BuildingData.data[type]["size"]
	sprite.texture = load(BuildingData.data[type]["icon_path"])

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

func can_place():
	return get_parent().can_place_at_position(global_position, size)

func _on_control_gui_input(event):
	if event is InputEventMouseButton && !placed:
		if event.is_action_pressed("left_click"):
			if type == BuildingData.Type.STAIRCASE and get_parent().stairs_placed:
				get_parent().get_parent().help_text_bar.text = "Stairs already placed! Can't have more than one staircase per floor"
				print("Stairs already placed!")
			if can_place() && in_bounds:
				placed = true
				get_parent().get_parent().help_text_is_overriden = false
				get_parent().on_building_placed(global_position, self)

				sprite.material = null
				return
		if event.is_action_pressed("right_click"):
			get_parent().placing = false
			get_parent().get_parent().help_text_is_overriden = false
			queue_free()
