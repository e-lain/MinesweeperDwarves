@tool
class_name BoardEntityView extends Node2D
## Base View Node for all Board Entities.
##
## Assumes existence of a Sprite2D child and must be assigned a BoardEntityModel on creation. 

## Sprite Name constant for configuration warning check
const SPRITE_NAME = "Sprite2D"
@onready var sprite: Sprite2D = get_node(SPRITE_NAME) as Sprite2D
var _model: BoardEntityModel

var _initialized = false

func init(model: BoardEntityModel) -> void:
	_model = model
	_initialized = true

func _ready():
	if !_initialized:
		push_error("A BoardEntityView has been added to the scene tree without init() being called!")

func _process(delta):
	if _model.is_placed():
		match_model_position()

func match_model_position() -> void:
	var bounds := _model.get_bounding_cell_rect()
	global_position = bounds.position * Globals.TILE_SIZE

func _get_configuration_warnings() -> PackedStringArray:
	for c in get_children():
		if c is Sprite2D and c.name == SPRITE_NAME:
			return []
	return ["Requires a Child of type Sprite2D with name Sprite2D"]
