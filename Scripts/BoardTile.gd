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

#var number_label_prefab: PackedScene = preload("res://Prefabs/NumberLabel.tscn")
#var flag_prefab: PackedScene = preload("res://Prefabs/Flag.tscn")
#var bomb_prefab: PackedScene = preload("res://Prefabs/Bomb.tscn")
#
#var label
#var flag
#var bomb
#
#var _label_parent: Node

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

#func create_label(adjacent_bomb_count: int):
#	if label != null:
#		label.queue_free()
#		label = null
#
#	if adjacent_bomb_count > 0:
#		label = number_label_prefab.instantiate()
#		_label_parent.add_child(label)
#		label.global_position = get_global_position()
#		label.set_number(adjacent_bomb_count)
#
#func create_flag():
#	flag = flag_prefab.instantiate()
#	_label_parent.add_child(flag)
#	flag.global_position = get_global_position()
#
#func destroy_flag():
#	if flag != null:
#		flag.queue_free()
#		flag = null

#func create_bomb(bomb_type: BombData.Type) -> Node2D:
#	bomb = bomb_prefab.instantiate()
#	bomb.set_type(bomb_type)
#	_label_parent.add_child(bomb)
#	bomb.global_position = get_global_position()
#	return bomb


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
	return entity.get_bomb_type() == BombData.Type.LAVA

#region SETTERS AND GETTERS
func get_entity_id() -> int:
	return _entity_id

func clear_entity_id() -> void:
	_entity_id = -1

func set_entity_id(id: int) -> void:
	_entity_id = id

func has_entity() -> bool:
	return _entity_id > 0
	
func is_uncovered() -> bool:
	return _state == TileState.Uncovered

#endregion

