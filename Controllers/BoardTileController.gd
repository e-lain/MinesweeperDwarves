class_name BoardTileController extends RefCounted
## Singleton Controller Class for all Board Tiles.
##
## Responsible for containing all the BoardTile data, as well as determining adjacency for board tiles
const EMPTY_RECT: Rect2i = Rect2i()

## Singleton instance
static var INSTANCE: BoardTileController

## 2D array of Board Tiles
var tiles: Array

var _entities_by_id := {}

## Boundaries of tiles array
var _bounds: Rect2i

## Tilemap which is the view for all BoardTiles. 
##
## Used for converting b/w world and cell coordinates. 
var _tilemap: SharedTileMap

## Constructor. Assigns self to singleton if not yet assigned.
func _init(size: Vector2i, tilemap: SharedTileMap) -> void:
	if INSTANCE == null:
		INSTANCE = self
	else:
		push_error("Attempted to create multiple BoardTileControllers")
		return
	
	_bounds = Rect2i(Vector2i.ZERO, size)
	_tilemap = tilemap
	
	tiles = []
	for c in size.x:
		tiles.append([])
		for r in size.y:
			var cell_pos := Vector2i(c, r)
			var t := BoardTile.new(cell_pos)
			tiles[c].append(t)

func refresh_tiles_in_bounds(bounds: Rect2i) -> void:
	for x in bounds.size.x:
		for y in bounds.size.y:
			var cell_pos := Vector2i(x, y) + bounds.position
			var tile := get_tile_at_cell_position(cell_pos)
			if tile.has_entity():
				var entity: BoardEntityModel = get_entity(tile.get_entity_id())
				entity.remove()
			
			tiles[cell_pos.x][cell_pos.y] = BoardTile.new(cell_pos)

## Returns the BoardTile at the given cell position
func get_tile_at_cell_position(cell_pos: Vector2i) -> BoardTile:
	assert(is_valid_position(EMPTY_RECT, cell_pos), "Attempted to get tile at invalid position: %s" % str(cell_pos))
	return tiles[cell_pos.x][cell_pos.y]

## Returns each boardtile at each given cell position. Convenience wrapper around get_til_at_cell_position
func get_tiles_at_cell_positions(cell_positions: Array[Vector2i]) -> Array[BoardTile]:
	var result: Array[BoardTile] = []
	for pos in cell_positions:
		result.append(get_tile_at_cell_position(pos))
	return result

func get_tiles_in_area(area: Rect2i) -> Array[BoardTile]:
	var result: Array[BoardTile] = []
	for x in area.size.x:
		for y in area.size.y:
			result.append(get_tile_at_cell_position(area.position + Vector2i(x, y)))
			
	return result

func is_area_in_bounds(area: Rect2i) -> bool:
	return _bounds.encloses(area)

func is_valid_position(extra_filter: Rect2i, position: Vector2i) -> bool:
	return _bounds.has_point(position) && (extra_filter == EMPTY_RECT || extra_filter.has_point(position))

## Returns the 4 tiles in each cardinal direction from the given BoardTile
##
## Optionally, provide a bounds filter Rect2i which prevents any tiles outside of the given bounds from being returned
func get_orthogonal_tiles(tile: BoardTile, bounds_filter: Rect2i = EMPTY_RECT) -> Array[BoardTile]:
	var offsets: Array[Vector2i] = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT,
	]
	
	return _get_tiles_at_offsets(tile, offsets, bounds_filter)

## Returns every tile located orthogonally from every tile in the given array, 
## A tile which is in the array but also orthogonal to another tile in the array will be exluded from the response.
func get_orthogonal_tiles_for_array(tiles: Array[BoardTile], bounds_filter: Rect2i = EMPTY_RECT) -> Array[BoardTile]:
	var result: Array[BoardTile] = []
	var offset_indices: Dictionary = {}
	
	for tile in tiles:
		offset_indices[cell_pos_to_index(tile.cell_position)] = true
	
	for tile in tiles:
		var orthogonal_tiles: Array[BoardTile] = get_orthogonal_tiles(tile, bounds_filter)
		
		for orthogonal_tile in orthogonal_tiles:
			var cell_pos: Vector2i = orthogonal_tile.cell_position
			var index = cell_pos_to_index(cell_pos)
			if !offset_indices.has(index):
				result.append(orthogonal_tile)
				offset_indices[index] = true
		
	return result


func cell_pos_to_index(cell_pos: Vector2i) -> int:
	return cell_pos.y * _bounds.size.x + cell_pos.x

func index_to_cell_pos(index: int) -> Vector2i:
	var y_val := int(index / _bounds.size.x)
	var x_val := index - y_val
	return Vector2i(x_val, y_val)

## Returns the 8 adjacent tiles in each direction from the given BoardTile
##
## Optionally, provide a bounds filter Rect2i which prevents any tiles outside of the given bounds from being returned
func get_adjacent_tiles(tile: BoardTile, bounds_filter: Rect2i = EMPTY_RECT) -> Array[BoardTile]:
	var offsets: Array[Vector2i] = [
		(Vector2i.UP + Vector2i.LEFT),
		(Vector2i.UP),
		(Vector2i.UP + Vector2i.RIGHT),
		(Vector2i.LEFT),
		(Vector2i.RIGHT),
		(Vector2i.DOWN + Vector2i.LEFT),
		(Vector2i.DOWN),
		(Vector2i.DOWN + Vector2i.RIGHT),
	]
	return _get_tiles_at_offsets(tile, offsets, bounds_filter)

## Returns an array of BoardTiles, each one which is at the 
func _get_tiles_at_offsets(tile: BoardTile, offsets: Array[Vector2i], bounds_filter: Rect2i) -> Array[BoardTile]:
	var surroundings: Array[BoardTile] = []
	for offset in offsets:
		var adjacent := tile.cell_position + offset
		if is_valid_position(bounds_filter, adjacent):
			surroundings.append(get_tile_at_cell_position(adjacent))
	return surroundings


func get_entity(id: int) -> BoardEntityModel:
	return _entities_by_id[id]

func register_entity(id: int, entity: BoardEntityModel) -> void:
	_entities_by_id[id] = entity

func unregister_entity(id: int) -> void:
	_entities_by_id.erase(id)
