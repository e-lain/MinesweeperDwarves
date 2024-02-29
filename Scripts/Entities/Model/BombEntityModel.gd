class_name BombEntityModel extends BoardEntityModel

var _bomb_type: BombData.Type:
	get = get_bomb_type

func get_bomb_type() -> BombData.Type:
	return _bomb_type


## Constructor
func _init(bounding_cell_rect: Rect2i, _type: BombData.Type):
	super(bounding_cell_rect)
	_bomb_type = _type
