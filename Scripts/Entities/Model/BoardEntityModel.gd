class_name BoardEntityModel extends RefCounted
## Model Object For Board Entities. 
## 
## Encapsulate a location, occupied tiles, and size. Can be moved with move() 

## ID of entity. Simple incrementing int
var _id: int = -1

## Whether or not this entity is placed on the board
var _is_placed: bool = false

## Origin Position and size of bounding rect.
## 
## An L-Shaped entity might only occupy 4 tiles, but have a bounding rect of size 2x3, for instance
var _bounding_cell_rect: Rect2i

## All Board Tiles which are occupied by this entity. No reliable order is expected. 
var _occupied_tiles: Array[BoardTile] = []


## Constructor.
func _init(bounding_cell_rect: Rect2i):
	_id = EntityIdController.INSTANCE.generate_id()
	BoardTileController.INSTANCE.register_entity(_id, self)
	_bounding_cell_rect = bounding_cell_rect

## Would permanently placing the entity at the current position be allowed?
func can_place() -> bool:
	if !BoardTileController.INSTANCE.is_area_in_bounds(_bounding_cell_rect):
		return false
	
	var tiles: Array[BoardTile] = BoardTileController.INSTANCE.get_tiles_in_area(_bounding_cell_rect)
	for tile in tiles:
		if tile.has_entity() || !tile.is_uncovered():
			return false
	
	return true

func place(bounding_cell_rect: Rect2i) -> void:
	_is_placed = true
	move(bounding_cell_rect)

## Move to a new location / collection of occupied tiles.
## 
## Emits updated signal.
func move(bounding_cell_rect: Rect2i) -> void:
	_bounding_cell_rect = bounding_cell_rect
	if is_placed():
		for tile in _occupied_tiles:
			tile.clear_entity_id()
		
		_occupied_tiles = BoardTileController.INSTANCE.get_tiles_in_area(_bounding_cell_rect)
		
		for tile in _occupied_tiles:
			tile.set_entity_id(_id)

#region Getters/Setters
func get_bounding_cell_rect() -> Rect2i:
	return _bounding_cell_rect

func get_occupied_tiles() -> Array[BoardTile]:
	return _occupied_tiles

func get_id() -> int:
	return _id
	
func is_placed() -> bool:
	return _is_placed
#endregion
