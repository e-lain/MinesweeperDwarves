extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
var building_placement_material: ShaderMaterial = preload("res://Shaders/InvalidBuildingPlacement.tres")

const TILE_SIZE = 64

var placed: bool = false
var in_bounds: bool = false
var size: int = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	get_parent().placing = true
	get_parent().get_parent().help_text_is_overriden = true

func _process(delta):
	get_parent().get_parent().help_text_bar.text = "Left-click on valid tile to clear it. If it has a bomb, you will not be harmed. Right-click to cancel"
	if get_parent().get_parent().ability_destroy < 1:
		get_parent().placing = false
		get_parent().get_parent().help_text_is_overriden = false
		queue_free()
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
	if get_parent().get_parent().ability_destroy < 1:
		return false
	return get_parent().can_use_ability_at_position(global_position, size) #Ability usage validity is opposite of building placement validity

func _input(event):
	if event is InputEventMouseButton && !placed:
		if event.is_action_pressed("left_click"):
			if can_place() && in_bounds:
				get_parent().get_parent().ability_destroy -= 1
				print("USED DESTROY ABILITY")
		if event.is_action_pressed("right_click"):
			get_parent().placing = false
			get_parent().clearing_tile = false
			get_parent().get_parent().help_text_is_overriden = false
			queue_free()
