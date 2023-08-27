extends Node2D
class_name Board

signal on_minesweeper_collection_complete
signal on_building_collection_complete
signal mine_animation_complete
signal wonder_placed
signal workshop_placed

@export var collection_lifespan_seconds: float = 1.5

@export var grid_line_prefab: PackedScene = preload("res://Prefabs/GridLine.tscn")
@onready var tilemap: TileMap = $TileMap

const collection_prefab = preload("res://UI/collection_effect.tscn")

var total_building_count = 0

var building_prefab = preload("res://Buildings/BaseBuilding.tscn")

var Destroy = preload("res://Abilities/Destroy.tscn")

const TILE_SIZE = 64

var build_mode: bool = false
var placing: bool = false
var placing_type: BuildingData.Type
var current_placing_instance: BaseBuilding

# Ability usage toggles
var clearing_tile: bool = false
var armor_active: bool = false

var rows = 6
var columns = 6
var bomb_count = 4

var flags = bomb_count

var bombs_found = 0
var tiles_uncovered = 0
var total_tiles = rows*columns

var tiles = []
var bomb_tiles = []

var stairs_placed: bool = false

var buildings_by_id := {}

var mine_exploded = false

# Called when the node enters the scene tree for the first time.
func _ready():
	get_parent().queue_building.connect(_on_building_queue)
	get_parent().queue_ability.connect(_on_ability_queue)
	randomize()
	
	tilemap.destroyed.connect(_on_tile_destroyed)
	tilemap.uncovered.connect(_on_tile_uncovered)
	tilemap.flag_toggled.connect(_on_flag_toggled)
	
func init_board(rows: int, cols: int, bombs: int):
	get_parent().build_mode = false
	
	self.rows = rows
	self.columns = cols
	self.bomb_count = bombs
	self.flags = self.bomb_count
	
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

func create_grid_lines():
	var offset = Vector2(TILE_SIZE, TILE_SIZE)
	var min_fade_pos = to_global(tilemap.map_to_local(Vector2i.ZERO)) - offset
	var max_fade_pos = min_fade_pos + Vector2(TILE_SIZE * columns, TILE_SIZE * rows) + offset
	
	for i in range(1, rows):
		var instance = grid_line_prefab.instantiate()
		add_child(instance)
		instance.position.x = 0
		instance.position.y = 64 * i
		instance.material.set_shader_parameter("speed", randf_range(0.01, 0.025) * (-1.0 if i % 2 == 0 else 1.0))
		instance.material.set_shader_parameter("min_fade_pos", min_fade_pos)
		instance.material.set_shader_parameter("max_fade_pos", max_fade_pos)
		
	for i in range(1, columns):
		var instance = grid_line_prefab.instantiate()
		add_child(instance)
		instance.global_rotation_degrees = 90
		instance.position.x = 64 * i
		instance.position.y = 360
		
		instance.material.set_shader_parameter("speed", randf_range(0.01, 0.025) * (-1.0 if i % 2 == 0 else 1.0))
		instance.material.set_shader_parameter("min_fade_pos", min_fade_pos)
		instance.material.set_shader_parameter("max_fade_pos", max_fade_pos)

func set_bombs():
	var n = 0
	while n < bomb_count:
		var bomb_index = randi() % (rows * columns)
		var tile = tiles[bomb_index / rows][bomb_index % rows]
		if tile.is_bomb == false:
			tile.set_bomb()
			bomb_tiles.append(tile)
			n += 1

func _process(delta):
	pass

func _on_building_queue(type: BuildingData.Type):
	if build_mode and !placing:
		placing = true
		placing_type = type
		get_parent().help_text_is_overriden = true
		get_parent().help_text_bar.text = "Left-click on valid space to build. Right-click to cancel"
		var building = building_prefab.instantiate()
		add_child(building)
		building.set_type(type)
		current_placing_instance = building

func _on_ability_queue(ability_name):
	var placing = true
	var ability
	if ability_name == "destroy" && get_parent().ability_destroy > 0:
		print("SIGNAL RECEIVED TO USE DESTROY ABILITY")
		ability = Destroy.instantiate()
		clearing_tile = true
	elif ability_name == "armor":
		print("SIGNAL RECEIVED TO USE ARMOR ABILITY")
		placing = false
		armor_active = true
		return
	elif ability_name == "dowse":
		print("SIGNAL RECEIVED TO USE DOWSE ABILITY")
		get_parent().ability_dowse -= 1
		placing = false
		if bomb_tiles.size() > 0:
			var picked = false
			while !picked:
				print("bomb tiles: ", bomb_tiles)
				randomize()
				var rand_index:int = randi() % bomb_tiles.size()
				if !bomb_tiles[rand_index].is_flagged:
					bomb_tiles[rand_index].toggle_flag()
					bombs_found += 1
					print("bombs found: ", bombs_found)
					flags -= 1
					picked = true
					return
		return
	add_child(ability)
	
func _on_tile_destroyed(cell_pos: Vector2i):
	if cell_pos.x < 0 || cell_pos.y < 0 || cell_pos.x >= columns || cell_pos.y >= rows:
		return
	print("tile destroyed called")
	var tile = tiles[cell_pos.x][cell_pos.y]
	clear_tile(tile)

func _on_tile_uncovered(cell_pos: Vector2i):
	if mine_exploded:
		return
	var tile = tiles[cell_pos.x][cell_pos.y]
	if tile.is_flagged:
		return
	
	if tile.is_bomb:
		print("status of armor active: ", armor_active)
		if !armor_active:
			get_parent().population -= 1
			explode_mine()
	
	SoundManager.play_uncover_tile_sound()
	
	uncover_tile(tile)
	update_shadows()

func enter_build_mode():
	get_parent().steel += bombs_found
	
	var has_steel_to_collect = false
	for x in columns:
		for y in rows:
			var tile = tiles[x][y]
			if tile.is_bomb && tile.is_flagged:
				var instance = collection_prefab.instantiate()
				add_child(instance)
				instance.position = Vector2(tile.get_position()) + (Vector2(TILE_SIZE, TILE_SIZE) / 2.0) + Vector2(-16, -16)
				instance.init(1, collection_lifespan_seconds,  "res://Assets/UI/steeldownscaledicon.png")
				has_steel_to_collect = true
	
	if has_steel_to_collect:
		var timer = get_tree().create_timer(collection_lifespan_seconds)
		timer.timeout.connect(minesweeper_collection_complete)
	else:
		minesweeper_collection_complete()
	
	
	
func on_building_placed(building_world_pos: Vector2, building: BaseBuilding):
	get_parent().help_text_is_overriden = false
	building.id = total_building_count
	var type = building.type
	var id = building.id
	placing = false
	total_building_count += 1
	var data = BuildingData.data[type]
	var size = data["size"]
	if !stairs_placed:
		stairs_placed = type == BuildingData.Type.STAIRCASE
	
	if data["population_cost"] > 0:
		get_parent().population -= data["population_cost"]
	
	if data["stone_cost"] > 0:
		get_parent().stone -= data["stone_cost"]
	
	if data["steel_cost"] > 0:
		get_parent().steel -= data["steel_cost"]
	
	var world_positions_to_update = get_world_positions_in_area(building_world_pos, size)
	for world_pos in world_positions_to_update:
		var cell_pos = tilemap.local_to_map(tilemap.to_local(world_pos))
		var tile = tiles[cell_pos.x][cell_pos.y]
		tile.has_building = true
		tile.building_id = id
	
	buildings_by_id[id] = building
	
	SoundManager.play_building_placement_sound()
	
		
	if type == BuildingData.Type.WORKSHOP:
		workshop_placed.emit()
	elif type == BuildingData.Type.WONDER:
		wonder_placed.emit()

func collect_resources():
	placing = false
	clearing_tile = false
	var directions = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	var tiles_to_collect_from = {}
	for id in buildings_by_id.keys():
		var building = buildings_by_id[id]
		var type = building.type
		
		if type == BuildingData.Type.MINECART:

			var cell_pos = tilemap.local_to_map(tilemap.to_local(building.global_position))
			for direction in directions:
				var check_cell = cell_pos + direction
				if check_cell.x < 0 || check_cell.y < 0 || check_cell.x >= columns || check_cell.y >= rows:
					continue
				var tile = tiles[check_cell.x][check_cell.y]
				if tile.has_building and !tiles_to_collect_from.has(tile.building_id):
					tiles_to_collect_from[tile.building_id] = tile
	
	
	var collected_resources = false
	for tile_id in tiles_to_collect_from.keys():
		var adjacent_type = buildings_by_id[tile_id].type
		var data = BuildingData.data[adjacent_type]
		
		var stone_cost = data["stone_cost"]
		var population_cost = data["population_cost"]
		var steel_cost = data["steel_cost"]
		
		# TODO - animate this
		if stone_cost < 0: # negative costs are resource gains
			get_parent().stone -= stone_cost
			buildings_by_id[tile_id].play_collection_animation(collection_lifespan_seconds, "res://Assets/UI/StoneIcon.png")
			collected_resources = true
		
		if population_cost < 0:
			get_parent().population -= population_cost
			buildings_by_id[tile_id].play_collection_animation(collection_lifespan_seconds, "res://Assets/UI/PopIcon.png")
			collected_resources = true
		
		if steel_cost < 0:
			get_parent().steel -= steel_cost
			buildings_by_id[tile_id].play_collection_animation(collection_lifespan_seconds, "res://Assets/UI/steeldownscaledicon.png")
			collected_resources = true
	
	if collected_resources:
		var timer = get_tree().create_timer(collection_lifespan_seconds)
		timer.timeout.connect(building_collection_complete)
		SoundManager.play_collection()
	else:
		# TODO: Notify player if not collecting any resources??
		building_collection_complete()

func building_collection_complete():
	on_building_collection_complete.emit()

func minesweeper_collection_complete():
	build_mode = true
	get_parent().build_mode = true
	for row in tiles:
		for tile in row:
			if tile.label:
				tile.label.queue_free()
			if tile.is_bomb:
				tile.destroy_bomb()
				bomb_tiles.erase(tile)

	on_minesweeper_collection_complete.emit()

func clear_tile(tile: BoardTile):
	if tile.is_flagged:
		flags += 1
		print("bombs found: ", bombs_found)
		tile.toggle_flag()
	uncover_tile(tile)
	update_shadows()

func uncover_tile(tile: BoardTile):
	tile.is_cover = false
	tiles_uncovered += 1
	tilemap.set_cells_terrain_connect(0, [tile.cell_position], 0, -1)
	
	if tile.is_bomb:
		var bomb = tile.create_bomb()
		if !armor_active && !clearing_tile:
			mine_exploded = true
			bomb.animation_complete.connect(on_bomb_animation_complete)
		return
	
	if get_parent().ability_destroy < 1:
		clearing_tile = false
		
	armor_active = false
		
	if tile.is_flagged:
		flags += 1
		tile.destroy_flag()
	
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

func explode_mine():
	# TODO: play an animation and emit signal when it finishes
	SoundManager.play_explosion_sound()

func on_bomb_animation_complete():
	mine_animation_complete.emit()

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
		
	if tile.is_flagged:
		flags += 1
	elif flags > 0:
		flags -= 1
	else:
		get_parent().help_text_is_overriden = true
		get_parent().help_text_bar.text = "All flags already placed, cannot place additional flags"
		await get_tree().create_timer(1).timeout
		get_parent().help_text_is_overriden = false
		return
		
	if !tile.is_cover:
		return
	if !tile.is_flagged && tile.is_bomb:
		bombs_found += 1
	elif tile.is_flagged && tile.is_bomb:
		bombs_found -= 1
	
	if !tile.is_flagged:
		SoundManager.play_flag_sound()
	print("bombs found: ", bombs_found)
	tile.toggle_flag()

func update_shadows():
	var used_cells = tilemap.get_used_cells(0)
	var occupied_tiles = {}
	
	for pos in used_cells:
		occupied_tiles[pos] = null
	var unused_cells = []
	for x in rows:
		for y in columns:
			var cell = Vector2i(x,y)
			if !occupied_tiles.has(cell):
				unused_cells.append(cell)
	
	tilemap.clear_layer(1)
	tilemap.set_cells_terrain_connect(1, unused_cells, 0, 1)

func can_place_at_position(world_pos: Vector2, size: int):
	var places_to_check = get_world_positions_in_area(world_pos, size)
	for pos in places_to_check:
		var cell_pos = tilemap.local_to_map(tilemap.to_local(pos))
		if cell_pos.x < 0 || cell_pos.x >= columns || cell_pos.y < 0 || cell_pos.y >= rows:
			return false
		var tile = tiles[cell_pos.x][cell_pos.y]
		if !(tilemap.get_cell_tile_data(0, cell_pos) == null && !tile.is_bomb && !tile.has_building):
			return false
			
	return true
	
func can_use_ability_at_position(world_pos: Vector2, size: int):
	var places_to_check = get_world_positions_in_area(world_pos, size)
	for pos in places_to_check:
		var cell_pos = tilemap.local_to_map(tilemap.to_local(pos))
		var tile = tiles[cell_pos.x][cell_pos.y]
		if tile.is_bomb && !tile.is_cover:
			return false
	return !can_place_at_position(world_pos, size)

func building_is_next_to_minecart(building: BaseBuilding) -> bool:
	var places_to_check = get_world_positions_in_area(building.global_position, building.size)
	var offsets = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]	

	for pos in places_to_check:
		var cell_pos = tilemap.local_to_map(tilemap.to_local(pos))
		for offset in offsets:
			var check = cell_pos + offset
			if check.x < 0 || check.x >= columns || check.y < 0 || check.y >= rows:
				continue
			var tile = tiles[check.x][check.y]
			var other_building = buildings_by_id[tile.building_id]
			if other_building.type == BuildingData.Type.MINECART:
				return true
	
	return false

func player_placing_minecart_next_to_building(building: BaseBuilding) -> bool:
	if !placing || placing_type != BuildingData.Type.MINECART || current_placing_instance == null:
		return false
	
	var minecart_cell_pos = tilemap.local_to_map(tilemap.to_local(current_placing_instance.global_position))
	var offsets = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for offset in offsets:
		var check = minecart_cell_pos + offset
		if check.x < 0 || check.x >= columns || check.y < 0 || check.y >= rows:
			continue
		var tile = tiles[check.x][check.y]
		if tile.building_id == building.id:
			return true
	return false
	
func get_world_positions_in_area(origin_world_pos: Vector2, size: int) -> Array[Vector2]:
	var tiles: Array[Vector2] = []
	for x in range(size):
		for y in range (size):
			tiles.push_back(Vector2(origin_world_pos.x + x*TILE_SIZE, origin_world_pos.y + y*TILE_SIZE))
	
	return tiles

func world_to_cell(world):
	return tilemap.local_to_map(tilemap.to_local(world))
