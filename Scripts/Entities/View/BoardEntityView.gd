@tool
class_name BoardEntityView extends Node2D

signal right_click_cancelled
signal on_placed
signal on_selected(selected: BoardEntityView)
signal on_deselected

## Base View Node for all Board Entities. init() must be called after instantiation
##
## Assumes existence of a Sprite2D child and must be assigned a BoardEntityModel on creation. 
@onready var sprite: Sprite2D = $Sprite2D
@onready var background: Sprite2D = $Background
@onready var control: Control = $Control

const bg_offset: Vector2i = Vector2i(3, 3)

var _model: BoardEntityModel

## A de-facto constructor. If this function is not called after the Scene is created, it will likely not work at all!
func init(model: BoardEntityModel) -> void:
	_model = model

func _process(_delta) -> void:
	match_model_position()

func _update_background() -> void:
	var size := _model._bounding_cell_rect.size
	if size == Vector2i.ONE:
		background.visible = false
	else:
		background.position = bg_offset
		var cell_pos: = _model.get_bounding_cell_rect().position
		var region_x = bg_offset.x + ((cell_pos.x % 8) * Globals.TILE_SIZE)
		var region_y = bg_offset.y + ((cell_pos.y % 8) * Globals.TILE_SIZE)
		var region_w = size.x * Globals.TILE_SIZE - bg_offset.x * 2
		var region_h = size.y * Globals.TILE_SIZE - bg_offset.y * 2
		background.region_rect = Rect2(region_x, region_y, region_w, region_h)

func match_model_position() -> void:
	var bounds := _model.get_bounding_cell_rect()
	global_position = bounds.position * Globals.TILE_SIZE
	_update_background()
	
func get_model() -> BoardEntityModel:
	return _model
