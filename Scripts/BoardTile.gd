class_name BoardTile extends RefCounted
## Encapsulate the position and status of a tile on a board
## TODO: cleanup functionality around spawning ui/visual elements

## Helper enum for BoardTile state
enum TileState {
	Covered,
	Flagged, ## Covered AND flagged
	Uncovered
}

## Coordinates of this tile in the Board tile grid. Not world position
var cell_position: Vector2i

## Entity id of an entity occupying this tile. -1 if none is present
var _entity_id: int = -1 : get = get_entity_id

var _state: TileState = TileState.Covered

func _init(cell_pos: Vector2i, label_parent: Node):
	cell_position = cell_pos
	#_label_parent = label_parent

func toggle_flag():
	if _state != TileState.Uncovered:
		if _state == TileState.Covered:
			_state = TileState.Flagged
			#create_flag()
		elif _state == TileState.Flagged:
			_state = TileState.Covered
			#destroy_flag()

func collect() -> Array[CostResource]:
	if !has_bomb() || !is_flagged():
		return []
	var entity: BombEntityModel = BoardTileController.INSTANCE.get_entity(get_entity_id())
	uncover()
	return entity.collect()

#func create_flag():
#	flag = flag_prefab.instantiate()
#	_label_parent.add_child(flag)
#	flag.global_position = get_global_position()

#func destroy_flag():
#	if flag != null:
#		flag.queue_free()
#		flag = null


## Returns this board tile's cell position converted to world coordinates
func get_global_position() -> Vector2:
	return cell_position * Globals.TILE_SIZE + Vector2i(Globals.TILE_SIZE / 2, Globals.TILE_SIZE / 2)

func has_bomb() -> bool:
	if !has_entity():
		return false
	
	var entity := BoardTileController.INSTANCE.get_entity(get_entity_id())
	return entity is BombEntityModel

func has_lava() -> bool:
	if !has_bomb:
		return false
	
	var entity: BombEntityModel = BoardTileController.INSTANCE.get_entity(get_entity_id())
	return entity.get_bomb_type() == BombData.Type.Lava

#region SETTERS AND GETTERS
func get_entity_id() -> int:
	return _entity_id

func clear_entity_id() -> void:
	_entity_id = -1

func set_entity_id(id: int) -> void:
	_entity_id = id

func has_entity() -> bool:
	return _entity_id > 0
	
func is_covered() -> bool:
	return _state == TileState.Covered

func is_uncovered() -> bool:
	return _state == TileState.Uncovered

func is_flagged() -> bool:
	return _state == TileState.Flagged

func uncover() -> void:
	_state = TileState.Uncovered
#endregion

