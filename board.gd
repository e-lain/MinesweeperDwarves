extends Node2D

@export var grid_line_prefab: PackedScene = preload("res://Prefabs/GridLine.tscn")
@onready var tilemap: TileMap = $TileMap

var Building = preload("res://Buildings/Building.tscn")
var Staircase = preload("res://Buildings/Staircase.tscn")
var Quarry = preload("res://Buildings/Quarry.tscn")
var House = preload("res://Buildings/House.tscn")

const TILE_SIZE = 64

var build_mode: bool = false
var placing: bool = false

var rows = 6
var columns = 6
var bomb_count = 4

var bombs_found = 0
var tiles_uncovered = 0
var total_tiles = rows*columns
var tiles = []

var stairs_placed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	get_parent().queue_building.connect(_on_building_queue)
	randomize()
	
	tilemap.uncovered.connect(_on_tile_uncovered)
	tilemap.flag_toggled.connect(_on_flag_toggled)
	
func init_board(rows: int, cols: int, bombs: int):
	self.rows = rows
	self.columns = cols
	self.bomb_count = bombs
	
	var fill_cells = []
	
	for c in columns:
		tiles.append([])
		for r in rows:
			var t = BoardTile.new()
			t.label_parent = self
			var cell_pos = Vector2i(c, r)
			t.cell_position = cell_pos
			tiles[c].append(t)
			fill_cells.append(cell_pos)
	
	tilemap.set_cells_terrain_connect(0, fill_cells, 0, 0)
	set_bombs()
	create_grid_lines()

func create_grid_lines():
	for i in 30:
		var instance
		if i < 12:
			instance = grid_line_prefab.instantiate()
			add_child(instance)
			instance.position.y = 64 * i
			instance.material.set_shader_parameter("speed", randf_range(0.01, 0.03) * (-1.0 if i % 2 == 0 else 1.0))
			
		instance = grid_line_prefab.instantiate()
		add_child(instance)
		instance.global_rotation_degrees = 90
		instance.position.x = 64 * i
		instance.position.y = 360
		
		instance.material.set_shader_parameter("speed", randf_range(0.01, 0.03) * (-1.0 if i % 2 == 0 else 1.0))

func set_bombs():
	var n = 0
	while n < bomb_count:
		var bomb_index = randi() % (rows * columns)
		var tile = tiles[bomb_index / rows][bomb_index % rows]
		if tile.is_bomb == false:
			tile.set_bomb()
			n += 1

func _process(delta):
	#if tiles_uncovered == total_tiles - bomb_count:
	#	enter_build_mode()
	#	print("TODO: LEVEL WIN! BUILD MODE ENGAGED")
	pass

func _on_building_queue(building_name):
	if build_mode and !placing:
		placing = true
		var building
		if building_name == "test":
			print("SIGNAL RECEIVED TO BUILD TEST BUILDING")
			building = Building.instantiate()
		if building_name == "staircase":
			print("SIGNAL RECEIVED TO BUILD STAIRCASE")
			building = Staircase.instantiate()
		if building_name == "quarry":
			print("SIGNAL RECEIVED TO BUILD QUARRY")
			building = Quarry.instantiate()
		if building_name == "house":
			print("SIGNAL RECEIVED TO BUILD HOUSE")
			building = House.instantiate()
		add_child(building)

func _on_tile_uncovered(cell_pos: Vector2i):
	var tile = tiles[cell_pos.x][cell_pos.y]
	if tile.is_flagged:
		return
	
	if tile.is_bomb:
		get_parent().population -= 1
		enter_build_mode()
		print("TODO: THE PLAYER HAS LOST, BUILD MODE ENGAGED")
	
	uncover_tile(tile)
	
	#update_shadows()

func enter_build_mode():
	build_mode = true
	bombs_found = 0
	tiles_uncovered = 0
	for row in tiles:
		for tile in row:
			if tile.label:
				tile.label.queue_free()

func on_building_placed(building_world_pos: Vector2, size: int, is_stairs: bool):
	placing = false
	stairs_placed = is_stairs
	
	var world_positions_to_update = get_world_positions_in_area(building_world_pos, size)
	for world_pos in world_positions_to_update:
		var cell_pos = tilemap.local_to_map(tilemap.to_local(world_pos))
		var tile = tiles[cell_pos.x][cell_pos.y]
		tile.has_building = true

func next_level():
	get_parent().next_level()
	hide()

func uncover_tile(tile: BoardTile):
	tile.is_cover = false
	tiles_uncovered += 1
	tilemap.set_cells_terrain_connect(0, [tile.cell_position], 0, -1)
	
	if tile.is_bomb:
		tile.create_bomb()
		return
	
	var adjacent_tiles = get_adjacent_tiles(tile)
	
	var adjacent_bombs = 0
	for adjacent_tile in adjacent_tiles:
		if adjacent_tile.is_bomb:
			adjacent_bombs += 1
	
	if adjacent_bombs > 0:
		tile.create_label(adjacent_bombs)
	else:
		for adjacent_tile in adjacent_tiles:
			if adjacent_tile.is_cover && !tile.is_bomb:
				uncover_tile(adjacent_tile)


func get_adjacent_tiles(tile: BoardTile) -> Array[BoardTile]:
	var surroundings: Array[BoardTile] = []
	var offsets = [
		(Vector2i.UP + Vector2i.LEFT),
		(Vector2i.UP),
		(Vector2i.UP + Vector2i.RIGHT),
		(Vector2i.LEFT),
		(Vector2i.RIGHT),
		(Vector2i.DOWN + Vector2i.LEFT),
		(Vector2i.DOWN),
		(Vector2i.DOWN + Vector2i.RIGHT),
	]
	
	for offset in offsets:
		var adjacent = tile.cell_position + offset
		if adjacent.x >= 0 && adjacent.x < columns && adjacent.y >= 0 && adjacent.y < rows:
			surroundings.append(tiles[adjacent.x][adjacent.y])
	return surroundings
	

func _on_flag_toggled(cell_pos: Vector2i):
	var tile = tiles[cell_pos.x][cell_pos.y]
	if !tile.is_cover:
		return
	if !tile.is_flagged && tile.is_bomb:
		bombs_found += 1
	elif tile.is_flagged && tile.is_bomb:
		bombs_found -= 1
	
	tile.toggle_flag()


func update_shadows():
	var used_cells = tilemap.get_used_cells(0)
	var occupied_tiles = {}
	
	var min_x = 9999999
	var max_x = -999999
	var min_y = 999999
	var max_y = -999999
	for pos in used_cells:
		if pos.x < min_x:
			min_x = int(pos.x)
		elif pos.x > max_x:
			max_x = int(pos.x)
		if pos.y < min_y:
			min_y = int(pos.y)
		elif pos.y > max_y:
			max_y = int(pos.y)
		
		occupied_tiles[pos] = null
	
	var unused_cells = []
	for x in range(min_x, max_x):
		for y in range(min_y, max_y):
			var cell = Vector2i(x,y)
			if !occupied_tiles.has(cell):
				unused_cells.append(cell)
	
	tilemap.clear_layer(1)
	tilemap.set_cells_terrain_connect(1, unused_cells, 0, 1)

func can_place_at_position(world_pos: Vector2, size: int):
	var places_to_check = get_world_positions_in_area(world_pos, size)
	for pos in places_to_check:
		var cell_pos = tilemap.local_to_map(tilemap.to_local(pos))
		if cell_pos.x < 0 || cell_pos.x >= columns || cell_pos.y < 0 || cell_pos.y > rows:
			return false
		var tile = tiles[cell_pos.x][cell_pos.y]
		if !(tilemap.get_cell_tile_data(0, cell_pos) == null && !tile.is_bomb && !tile.has_building):
			return false
			
	return true

func get_world_positions_in_area(origin_world_pos: Vector2, size: int) -> Array[Vector2]:
	var tiles: Array[Vector2] = []
	for x in range(size):
		for y in range (size):
			tiles.push_back(Vector2(origin_world_pos.x + x*TILE_SIZE, origin_world_pos.y + y*TILE_SIZE))
	
	return tiles
