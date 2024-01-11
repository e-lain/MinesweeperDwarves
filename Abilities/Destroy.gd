extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var board = get_parent()
@onready var main = board.get_parent()
var building_placement_material: ShaderMaterial = preload("res://Shaders/InvalidBuildingPlacement.tres")

const TILE_SIZE = 64

var placed: bool = false
var in_bounds: bool = false
var size: int = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	main.help_text_is_overriden = true

func _process(delta):
	main.help_text_bar.text = "Left-click on valid tile to clear it. If it has a bomb, you will not be harmed. Right-click to cancel"
	if main.get_ability_charge_count(AbilityData.Type.DESTROY) < 1 && visible:
		board.complete_ability()
		main.help_text_is_overriden = false
		queue_free()
	if !placed:
		var mouse = board.get_local_mouse_position()
		var snapped = Vector2(snapped(mouse.x-TILE_SIZE/2, TILE_SIZE), snapped(mouse.y-TILE_SIZE/2, TILE_SIZE))
		position = snapped
		if position.x <= 0 - TILE_SIZE || position.x >= TILE_SIZE * board.rows || position.y <= 0-TILE_SIZE || position.y >= TILE_SIZE * board.columns:
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
	if main.get_ability_charge_count(AbilityData.Type.DESTROY) < 1:
		return false
	return board.can_use_ability_at_position(global_position, size) #Ability usage validity is opposite of building placement validity

func _input(event):
	if event is InputEventMouseButton && !placed:
		if event.is_action_pressed("left_click"):
			if can_place() && in_bounds:
				main.use_ability_charge(AbilityData.Type.DESTROY)
				print("USED DESTROY ABILITY")
		if event.is_action_pressed("right_click"):
			board.clearing_tile = false
			main.help_text_is_overriden = false
			board.complete_ability()
			queue_free()
