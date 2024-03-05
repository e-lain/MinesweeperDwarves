class_name BaseEnemyModel extends BoardEntityModel

var _tiles_in_range: Array[BoardTile] : get = get_tiles_in_range

func move(bounding_cell_rect: Rect2i) -> void:
	super(bounding_cell_rect)
	_update_tiles_in_range()

func _update_tiles_in_range() -> void:
	_tiles_in_range = []
	# default pattern is every boardtile adjacent to occupied tiles

func get_tiles_in_range() -> Array[BoardTile]:
	return _tiles_in_range
