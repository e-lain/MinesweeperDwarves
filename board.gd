extends Node2D
class_name Board

const TILE_SIZE = 64

signal tile_uncover_event_complete
signal tile_flagged_event_complete

signal on_minesweeper_collection_complete
signal on_building_collection_complete
signal mine_animation_complete
signal wonder_placed
signal workshop_placed
signal workshop_destroyed

signal placing_building_instantiated(building: BaseBuilding)
signal building_placed
signal building_selected(building: BaseBuilding)
signal building_deselected

signal ability_complete

@export var collection_lifespan_seconds: float = 1.5

@export var grid_line_prefab: PackedScene = preload("res://Prefabs/GridLine.tscn")
@onready var tilemap: TileMap = $TileMap

const collection_prefab = preload("res://UI/collection_effect.tscn")

var total_building_count = 0

var building_prefab = preload("res://Buildings/BaseBuilding.tscn")

var Destroy = preload("res://Abilities/Destroy.tscn")

var ability_controller

var placing_type: BuildingData.Type
var current_placing_instance: BaseBuilding

# Ability usage toggles
var clearing_tile: bool = false
var armor_active: bool = false

var tier: int
var rows = 6
var columns = 6
var bomb_count = 4

var flags = bomb_count

var bombs_found = 0
var tiles_uncovered = 0
var total_tiles = rows*columns

var tiles = []
var bomb_tiles = []
var lava_tiles = {} # NOTE: Lava source tiles are placed via some building placement logic, but ARE NOT TREATED AS BULIDINGS
# They are not classified as such, and consequently do not have building id either

var stairs_placed: bool = false

var buildings_by_id := {}

var mine_exploded = false

var state := State.Play

var selected_building

var moving_building_original_world_position

enum State {
	Play,
	Build,
	MobilePrePlacing,
	Placing,
	Ability,
	Complete,
	Selected,
	Moving
}

# Called when the node enters the scene tree for the first time.
func _ready():
	ability_controller = AbilityController.new()
	add_child(ability_controller)

	randomize()
	
	tilemap.destroyed.connect(_on_tile_destroyed)
	tilemap.uncovered.connect(_on_tile_uncovered)
	tilemap.flag_toggled.connect(_on_flag_toggled)
	
func init_board(rows: int, cols: int, bombs: int, tier: int):
	get_parent().build_mode = false
	self.tier = tier
	
	self.rows = rows
	self.columns = cols
	self.bomb_count = bombs
	self.flags = self.bomb_count
	lava_tiles = {}
	
	tiles = tilemap.fill(columns, rows, tier)
	set_bombs()

	
func _unhandled_input(event):
	if state == State.MobilePrePlacing and event is InputEventScreenTouch:
		get_viewport().set_input_as_handled()
		enter_placing(placing_type)
		
		current_placing_instance.place(get_global_mouse_position())

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
			# Determine which type the bomb will be
			var types = BiomeData.get_bombs(get_parent().tier)
			var type_index = randi() % (types.size())
			var bomb_type = types[type_index]
			
			tile.set_bomb(bomb_type)
			bomb_tiles.append(tile)
			n += 1

func queue_building(type: BuildingData.Type):
	if state == State.Build:
		if PlatformUtil.isMobile():
			state = State.MobilePrePlacing
			placing_type = type
			current_placing_instance = null
		else:
			enter_placing(type)

func enter_placing(type: BuildingData.Type):
	state = State.Placing
	placing_type = type
	
	var building = building_prefab.instantiate()
	add_child(building)
	building.set_type(type, get_parent().icons[type])
	current_placing_instance = building
	current_placing_instance.on_placed.connect(on_building_placed)
	placing_building_instantiated.emit(current_placing_instance)

func queue_ability(ability_name: AbilityData.Type):
	state = State.Ability
	ability_controller.activate_ability(ability_name)
	
func complete_ability():
	state = State.Play
	ability_complete.emit()
	
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
			Resources.amounts[ResourceData.Resources.POPULATION] -= 1
			explode_mine()
	
	SoundManager.play_uncover_tile_sound()
	
	uncover_tile(tile)
	update_shadows()
	tile_uncover_event_complete.emit()
	

func enter_build_mode():
	var has_steel_to_collect = false
	for x in columns:
		for y in rows:
			var tile = tiles[x][y]
			if tile.is_bomb && tile.is_flagged:
				if tile.bomb_type == BombData.Type.DEFAULT:
					Resources.amounts[ResourceData.Resources.STEEL] += 1
					var instance = collection_prefab.instantiate()
					add_child(instance)
					instance.position = Vector2(tile.get_position()) + (Vector2(TILE_SIZE, TILE_SIZE) / 2.0) + Vector2(-16, -16)
					instance.init(1, collection_lifespan_seconds,  "res://Assets/UI/steeldownscaledicon.png")
					has_steel_to_collect = true
				elif tile.bomb_type == BombData.Type.LAVA:
					place_lava_from_bomb(tile)
	
	if has_steel_to_collect:
		var timer = get_tree().create_timer(collection_lifespan_seconds)
		timer.timeout.connect(minesweeper_collection_complete)
	else:
		minesweeper_collection_complete()

func place_lava_from_bomb(tile: BoardTile):
	if tile.is_flagged: # Should always be true but I'm one paranoid little baby
		tile.toggle_flag()
	tile.is_cover = false
	tiles_uncovered += 1
	tilemap.remove_tile(tile.cell_position)
	tilemap.set_lava_source(tile.cell_position)
	update_shadows()
	
	# Create lava source buliding on tile. THIS IS NOT TREATED AS A BUILDING BY THE LOGIC
	var building = building_prefab.instantiate()
	var lava_type = BuildingData.Type.LAVA
	add_child(building)
	building.set_type(lava_type, get_parent().icons[lava_type])
	current_placing_instance = building
	building.confirm_placement()
	var tile_pos = tile.get_position()
	var snapped = Vector2(snapped(tile_pos.x-TILE_SIZE/2, TILE_SIZE), snapped(tile_pos.y-TILE_SIZE/2, TILE_SIZE))
	building.position = snapped
	building.sprite.material = null
	
	# Add tile to lava_tiles dictionary, assign UID to lava source
	tile.lava_uid = "s" + str(lava_tiles.size())
	lava_tiles[tile.lava_uid] = tile
	
# Iterate through each lava tile in lava_tiles and refresh its connected_sources values
# Logic controls lava pathing and validity
func refresh_lava_connections() -> void:
	# Wipe all existing connected_sources
	print("lava tiles: ", lava_tiles)
	for tile in lava_tiles.values():
		buildings_by_id[tile.building_id].connected_lava_sources = []
	
	# Path out from all source tiles, to register all connected moats as linked to it
	for tile in lava_tiles.values():
		if tile.is_bomb && tile.bomb_type == BombData.Type.LAVA:
			var source_uid = str(tile.lava_uid)
			var adjacent_tiles = get_adjacent_tiles(tile)
			for adj_tile in adjacent_tiles:
				var check = adj_tile.cell_position
				if tile_out_of_bounds(adj_tile):
					print("Adjacent to source: out of bounds!")
					continue
				if !adj_tile.has_building:
					print("Adjacent to source: no moat")
					continue
				print("Adjacent to source: Building Type is ", buildings_by_id[adj_tile.building_id].type)
				if buildings_by_id[adj_tile.building_id].type == BuildingData.Type.LAVA:
					print("Lava source ", source_uid, " has an adjacent lava tile at ", adj_tile.cell_position)
					register_lava_connections(source_uid, adj_tile)
				else:
					print("Adjacent to source: Something went wrong")

	# Update visual icon of lava moats to reflect whether or not they are connected
	for tile in lava_tiles.values():
		var building_on_tile
		if tile.has_building && buildings_by_id[tile.building_id].type == BuildingData.Type.LAVA:
			building_on_tile = buildings_by_id[tile.building_id]
		if building_on_tile:
			if building_on_tile.connected_lava_sources.size() < 2:
				# TODO: REFACTOR
				building_on_tile.no_minecart_sprite.visible = true
			else:
				building_on_tile.no_minecart_sprite.visible = false
	return
	
# Recursive function which will register connected lava source, and then recurse to neighboring lava moats
# Terminates upon reaching a lava source, or if the tile source is already registered to the provided source (it is doubling back)
func register_lava_connections(source_uid: String, tile: BoardTile) -> void:
	# Get connected_lava_sources array, if able
	var building_on_tile
	var connected_sources
	if tile.has_building && buildings_by_id[tile.building_id] && buildings_by_id[tile.building_id].type == BuildingData.Type.LAVA:
		building_on_tile = buildings_by_id[tile.building_id]
	if building_on_tile:
		connected_sources = building_on_tile.connected_lava_sources

	# Check termination clauses
	var contains_source_uid: bool = false
	for uid in connected_sources:
		if uid == source_uid:
			contains_source_uid = true
			continue
	if (tile.is_bomb && tile.bomb_type == BombData.Type.LAVA) || (contains_source_uid):
		return
		
	# Add source_uid to connected_sources
	building_on_tile.connected_lava_sources.append(source_uid)
	
	# Recursively call on neighboring tiles
	var offsets = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for offset in offsets:
		var check = tile.cell_position + offset
		if check.x < 0 || check.x >= columns || check.y < 0 || check.y >= rows:
			continue
		var adjacent_tile = tiles[check.x][check.y]
		if !adjacent_tile.has_building:
			continue
		if buildings_by_id[adjacent_tile.building_id].type == BuildingData.Type.LAVA:
			register_lava_connections(source_uid, adjacent_tile)
	return

func on_building_placed():
	if state == State.Moving:
		return
	if state != State.Placing:
		push_error("Invalid state when building placed!")
		return
	
	building_placed.emit()
	
func on_cancel_building_placement():
	state = State.Build
	if current_placing_instance != null:
		current_placing_instance.cancel_placement()
		current_placing_instance = null

func on_confirm_building_placement():
	var building = current_placing_instance
	var building_world_pos = building.global_position
	
	building.confirm_placement()
	building.on_selected.connect(on_building_selected)
	
	get_parent().help_text_is_overriden = false
	building.id = total_building_count
	var type = building.type
	var id = building.id
	total_building_count += 1
	var data = BuildingData.data[type]
	var size = data["size"]
	if !stairs_placed:
		stairs_placed = type == BuildingData.Type.STAIRCASE
	
	
	var costs = BuildingData.get_costs(type)
	
	for cost_type in costs.keys():
		if costs[cost_type] > 0:
			Resources.amounts[cost_type] -= costs[cost_type]
	

	var tile
	var world_positions_to_update = get_world_positions_in_area(building_world_pos, size)
	for world_pos in world_positions_to_update:
		var cell_pos = tilemap.local_to_map(tilemap.to_local(world_pos))
		tile = tiles[cell_pos.x][cell_pos.y]
		tile.has_building = true
		tile.building_id = id
	
	buildings_by_id[id] = building
	
	SoundManager.play_building_placement_sound()
	
		
	if type == BuildingData.Type.WORKSHOP:
		workshop_placed.emit()
	elif type == BuildingData.Type.WONDER:
		wonder_placed.emit()
		
	state = State.Build
	
	# If placed building is a lava moat, register it with the lava_tiles dictionary in board, and refresh board's lava pathing
	if type == BuildingData.Type.LAVA:
		if tile:
			lava_tiles[tile.building_id] = (tile)
			building.set_building_visibility(false)
			tilemap.set_lava_moat(tile.cell_position)
			refresh_lava_connections()
			print("CONNECTIONS: ", building.connected_lava_sources)
		else:
			print("ERROR: No tile at specified coordinates of placed lava building")

func on_building_selected(building: BaseBuilding):
	if state == State.Selected && building != selected_building:
		selected_building.deselect(null)
	
	building_selected.emit(building)
	state = State.Selected
	selected_building = building
	selected_building.on_deselected.connect(on_building_deselected)
	
func deselect_building(event = null):
	if state == State.Selected:
		selected_building.deselect(event)

func on_building_deselected():
	if state == State.Selected:
		building_deselected.emit()
		selected_building.on_deselected.disconnect(on_building_deselected)
		state = State.Build
		selected_building = null

func destroy_selected_building():
	if state != State.Selected:
		push_error("Attempting to destroy selected building when not in selected state")
		return
	
	var building = selected_building
	# updates the UI
	deselect_building()

	var building_world_pos = building.global_position

	var type = building.type
	var id = building.id
	
	var data = BuildingData.data[type]
	var size = data["size"]

	# Remove from lava_tiles list if it's a lava moat
	# Refresh moat connection status icons
	if type == BuildingData.Type.LAVA:
		lava_tiles.erase(id)
		refresh_lava_connections()
	
	var costs = BuildingData.get_costs(type)
	
	for cost_type in costs.keys():
		if costs[cost_type] > 0:
			Resources.amounts[cost_type] += costs[cost_type]
	
	var world_positions_to_update = get_world_positions_in_area(building_world_pos, size)
	for world_pos in world_positions_to_update:
		var cell_pos = tilemap.local_to_map(tilemap.to_local(world_pos))
		var tile = tiles[cell_pos.x][cell_pos.y]
		tile.has_building = false
		tile.building_id = 0
		if type == BuildingData.Type.LAVA:
			tilemap.remove_tile(cell_pos)
			lava_tiles.erase(tile)
			tile.lava_uid = 0
			refresh_lava_connections()
	
	buildings_by_id.erase(id)
	
	building.queue_free()
	
	state = State.Build
	
	if type == BuildingData.Type.WORKSHOP:
		workshop_destroyed.emit()

func move_selected_building():
	if state != State.Selected:
		push_error("tried to move selected building while board not in selected state")
		return
	
	state = State.Moving
	var type = selected_building.type
	var id = selected_building.id
	var data = BuildingData.data[type]
	var size = data["size"]
	moving_building_original_world_position = selected_building.global_position
	
	var old_world_positions = get_world_positions_in_area(moving_building_original_world_position, size)
	for world_pos in old_world_positions:
		var cell_pos = tilemap.local_to_map(tilemap.to_local(world_pos))
		var tile = tiles[cell_pos.x][cell_pos.y]
		tile.has_building = false
		tile.building_id = 0
	
	selected_building.place(selected_building.global_position)
	

func confirm_selected_building_move():
	if state != State.Moving:
		push_error("Tried to confirm building move while board not in moving state")
		return
	
	state = State.Selected
	var type = selected_building.type
	var id = selected_building.id
	var data = BuildingData.data[type]
	var size = data["size"]
		
	var new_world_positions = get_world_positions_in_area(selected_building.global_position, size)
	for world_pos in new_world_positions:
		var cell_pos = tilemap.local_to_map(tilemap.to_local(world_pos))
		var tile = tiles[cell_pos.x][cell_pos.y]
		tile.has_building = true
		tile.building_id = selected_building.id
	
	selected_building.confirm_placement()
	# Update UI
	deselect_building()
	
func cancel_selected_building_move():
	if state != State.Moving:
		push_error("Tried to cancel building move while board not in moving state")
		return
	
	state = State.Selected
	var type = selected_building.type
	var id = selected_building.id
	var data = BuildingData.data[type]
	var size = data["size"]
	
	

	var old_world_positions = get_world_positions_in_area(moving_building_original_world_position, size)
	for world_pos in old_world_positions:
		var cell_pos = tilemap.local_to_map(tilemap.to_local(world_pos))
		var tile = tiles[cell_pos.x][cell_pos.y]
		tile.has_building = true
		tile.building_id = selected_building.id
	
	
	selected_building.global_position = moving_building_original_world_position
	selected_building.confirm_placement()
	deselect_building()

func collect_resources():
	state = State.Complete
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
		
		var costs = BuildingData.get_costs(adjacent_type)
	
		for cost_type in costs.keys():
			if costs[cost_type] < 0:
				Resources.amounts[cost_type] -= costs[cost_type]
				buildings_by_id[tile_id].play_collection_animation(collection_lifespan_seconds, "res://Assets/UI/StoneIcon.png")
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
	state = State.Build
	
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
	tilemap.remove_tile(tile.cell_position)
	
	if tile.is_bomb:
		var bomb = tile.create_bomb(tile.bomb_type)
		if !armor_active && !clearing_tile:
			mine_exploded = true
			bomb.animation_complete.connect(on_bomb_animation_complete)
		return
	
	if get_parent().get_ability_charge_count(AbilityData.Type.DESTROY) < 1:
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
	tile_flagged_event_complete.emit()

func update_shadows():
	tilemap.update_shadows(columns, rows)

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
		if cell_pos.x >= columns || cell_pos.y >= rows || cell_pos.x < 0 || cell_pos.y < 0:
			return false
		var tile = tiles[cell_pos.x][cell_pos.y]
		if tile.is_bomb && !tile.is_cover:
			return false
	return !can_place_at_position(world_pos, size)

func tile_out_of_bounds(tile: BoardTile) -> bool:
	var cell_pos = tile.cell_position 
	var x = cell_pos.x
	var y = cell_pos.y
	
	if x < 0 || x >= columns || y < 0 || y >= rows:
		return true
	return false

# Returns array of adjacent board coordinates from provided array of global positions
# NOTE: INPUT POSITIONS ARE GLOBAL, RETURNED POSITIONS ARE BOARD-RELATIVE
func get_adjacent_positions(global_positions: Array[Vector2]) -> Array[Vector2]:
	var offsets = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var board_adjacent_coordinates: Array[Vector2] = []
	
	for pos in global_positions:
		for offset in offsets:
			board_adjacent_coordinates.append(tilemap.local_to_map(tilemap.to_local(pos)) + offset)
	return board_adjacent_coordinates

# Returns the board tiles of provided array of global positions 
func get_tiles_from_positions(positions: Array[Vector2]) -> Array[BoardTile]:
	var output_tiles: Array[BoardTile] = []
	
	for pos in positions:
		output_tiles.append(tiles[pos.x][pos.y])
	return output_tiles

# Returns array of tiles a building is on
func get_tiles_of_building(building: BaseBuilding) -> Array[BoardTile]:
	var positions_to_check = get_world_positions_in_area(building.global_position, building.size)
	var building_tiles = get_tiles_from_positions(positions_to_check)
	return building_tiles

# Returns if tile provided is next to a certain type of building
func tile_is_next_to_building_type(tile: BoardTile, type: BuildingData.Type) -> bool:
	var adjacent_tiles = get_adjacent_tiles(tile)
	for adj_tile in adjacent_tiles:
		if adj_tile.has_building && buildings_by_id[adj_tile.building_id] == type:
			return true
	return false

func building_is_next_to_minecart(building: BaseBuilding) -> bool:
	var places_to_check = get_world_positions_in_area(building.global_position, building.size)
	var adjacent_positions = get_adjacent_positions(places_to_check)
	var adjacent_tiles = get_tiles_from_positions(adjacent_positions)
	
	var offsets = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]	

	for pos in places_to_check:
		var cell_pos = tilemap.local_to_map(tilemap.to_local(pos))
		for offset in offsets:
			var check = cell_pos + offset
			if check.x < 0 || check.x >= columns || check.y < 0 || check.y >= rows:
				continue
			var tile = tiles[check.x][check.y]
			if !tile.has_building:
				continue
			var other_building = buildings_by_id[tile.building_id]
			if other_building.type == BuildingData.Type.MINECART:
				return true
	return false

# TODO: See if we can use tiles_is_next_to_building_type here
func building_is_next_to_lava(building: BaseBuilding) -> bool:
	var places_to_check = get_world_positions_in_area(building.global_position, building.size)
	var offsets = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]	

	for pos in places_to_check:
		var cell_pos = tilemap.local_to_map(tilemap.to_local(pos))
		for offset in offsets:
			var check = cell_pos + offset
			if check.x < 0 || check.x >= columns || check.y < 0 || check.y >= rows:
				continue
			var tile = tiles[check.x][check.y]
			var other_building
			if tile.has_building:
				other_building = buildings_by_id[tile.building_id]
			# Ensure adjacent building is lava source or valid lava building
			# TODO: Also check if moat is properly connected
			if (other_building && other_building.type == BuildingData.Type.LAVA && !tile.is_bomb && other_building.connected_lava_sources > 1):
				return true
	return false

func player_placing_minecart_next_to_building(building: BaseBuilding) -> bool:
	if state != State.Placing || placing_type != BuildingData.Type.MINECART || current_placing_instance == null:
		return false
	
	var minecart_cell_pos = tilemap.local_to_map(tilemap.to_local(current_placing_instance.global_position))
	var offsets = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for offset in offsets:
		var check = minecart_cell_pos + offset
		if check.x < 0 || check.x >= columns || check.y < 0 || check.y >= rows:
			continue
		var tile = tiles[check.x][check.y]
		if !tile.has_building:
			continue
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

func are_all_buildings_being_exploited() -> bool:
	for building in buildings_by_id.values():
		if building.requires_minecart_adjacency() && !building.next_to_minecart():
			return false
		if building.requires_lava_adjacency() && !building.next_to_lava():
			return false
	
	return true

func is_cleared():
	return tiles_uncovered + bombs_found == rows * columns
