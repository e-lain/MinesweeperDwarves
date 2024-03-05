class_name Board extends Node2D

signal tile_uncover_event_complete
signal tile_flagged_event_complete

signal on_minesweeper_collection_complete
signal on_building_collection_complete
signal mine_animation_complete
signal wonder_placed
signal workshop_placed
signal workshop_destroyed

signal placing_building_instantiated(building: BuildingEntityView)
signal building_placed
signal building_selected(building: BuildingEntityView)
signal building_deselected
signal building_right_click_cancelled

var tilemap: SharedTileMap

const collection_prefab: PackedScene = preload("res://UI/collection_effect.tscn")

var total_building_count: int = 0

var placing_type: BuildingData.Type

var current_placing_instance: BuildingEntityView

var tier: int
var rows = 6
var columns = 6
var bomb_count = 4

var flags = bomb_count

var bombs_initialized: bool = false

var bombs_found = 0
var tiles_uncovered = 0
var total_tiles = rows*columns

#TODO: populate this programmatically
var unlock_costs = { ResourceData.Resources.POPULATION: 1 }

var tiles := []
var number_labels := []
var flags_by_cell_pos := {}


var stairs_placed: bool = false

var building_views_by_entity_id := {}
var bomb_views_by_entity_id := {}

var mine_exploded = false

var state := State.Play

var selected_building

var moving_building_origin_cell_pos

var overworld_room_id: int = -1

var tilemap_origin_cell_pos: Vector2i

var number_label_prefab: PackedScene = preload("res://Prefabs/NumberLabel.tscn")
var flag_prefab: PackedScene = preload("res://Prefabs/Flag.tscn")

enum State {
	Play,
	Build,
	MobilePrePlacing,
	Placing,
	Ability,
	Complete,
	Selected,
	Moving, 
	Locked,
	Deactivated
}

func init_board(rows: int, cols: int, bombs: int, tier: int, tilemap: SharedTileMap, tilemap_origin_cell_pos: Vector2i):
	self.tier = tier
	
	self.rows = rows
	self.columns = cols
	self.bomb_count = bombs
	self.flags = self.bomb_count
	self.tilemap = tilemap
	self.tilemap_origin_cell_pos = tilemap_origin_cell_pos

	tiles = []
	for c in columns:
		tiles.append([])
		for r in rows:
			var cell_pos: Vector2i = tilemap_origin_cell_pos + Vector2i(c, r)
			tiles[c].append(BoardTileController.INSTANCE.get_tile_at_cell_position(cell_pos))
	
func _unhandled_input(event):
	if state == State.MobilePrePlacing and event is InputEventScreenTouch:
		get_viewport().set_input_as_handled()
		enter_placing(placing_type)
		
		current_placing_instance.place()

func set_bombs(first_click_pos: Vector2i):
	var indices: Array[int] = []
	var tile_count: int = rows * columns
	var first_click_tile: BoardTile = BoardTileController.INSTANCE.get_tile_at_cell_position(first_click_pos)
	var adjacent_to_first_click: Array[BoardTile] = BoardTileController.INSTANCE.get_adjacent_tiles(first_click_tile)
	adjacent_to_first_click.append(first_click_tile)
	var adjacent_indices = {}
	for tile in adjacent_to_first_click:
		var adjusted_pos: Vector2i = tile.cell_position - tilemap_origin_cell_pos
		adjacent_indices[adjusted_pos.y + (adjusted_pos.x * rows)] = true
	
	for i in tile_count:
		if !adjacent_indices.has(i):
			indices.push_back(i)
	indices.shuffle()
	
	var n: int = 0
	while n < bomb_count:
		var bomb_index: int = indices.pop_front()
		var tile: BoardTile = tiles[bomb_index / rows][bomb_index % rows]
		# Determine which type the bomb will be
		var types:Array[BombData.Type] = BiomeData.get_bombs(get_parent().tier)
		var type_index: int = randi() % (types.size())
		var bomb_type: BombData.Type = types[type_index]
		
		
		var bounding_rect := Rect2i(tile.cell_position,Vector2i(1,1))
		
		var bomb_entity: BombEntityModel = BombData.get_bomb_data(bomb_type).model_script.new(bounding_rect, bomb_type)
		bomb_entity.place(bounding_rect)
		
		tile.set_entity_id(bomb_entity.get_id())
		n += 1
	bombs_initialized = true

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
	
	var data := BuildingData.INSTANCE.get_building_data(type)
	
	var building: BuildingEntityView = data.scene.instantiate()
	
	var origin_pos: Vector2i = get_boundaries_rect().position + (get_boundaries_rect().size / 2)
	
	var model: BaseBuildingEntityModel = data.model_script.new(origin_pos, type)
	add_child(building)
	building.init(model)
	current_placing_instance = building
	current_placing_instance.on_placed.connect(on_building_placed)
	current_placing_instance.right_click_cancelled.connect(on_building_right_click_cancel)
	placing_building_instantiated.emit(current_placing_instance)

func _on_tile_uncovered(cell_pos: Vector2i):
	if mine_exploded || !contains_cell_position(cell_pos):
		return
	
	if !bombs_initialized:
		set_bombs(cell_pos)
	
	var tile := BoardTileController.INSTANCE.get_tile_at_cell_position(cell_pos)
	if tile.is_flagged():
		return
	
	if tile.has_bomb():
		Resources.update_amount(ResourceData.Resources.POPULATION, -Globals.MINE_HIT_POPULATION_COST)
		explode_mine()
	
	SoundManager.play_uncover_tile_sound()
	
	uncover_tile(tile)
	tilemap.update_terrain(get_boundaries_rect())
	tile_uncover_event_complete.emit()

func enter_build_mode() -> void:
	var has_steel_to_collect := false
	var collected_count := 0
	for x in columns:
		for y in rows:
			var tile: BoardTile = tiles[x][y]
			if tile.has_bomb() && tile.is_flagged():
				var collection: Array[CostResource] = tile.collect()
				if collection.size() > 0:
					Resources.add_amounts(collection)
					var instance = collection_prefab.instantiate()
					add_child(instance)
					
					instance.global_position = Globals.cell_to_global(tile.cell_position)
					instance.init(collection, collected_count)
					collected_count += 1
				
				uncover_tile(tile, 0, 0, false)
				create_bomb_view(tile)
	
	tilemap.update_terrain(get_boundaries_rect())
	
	if has_steel_to_collect:
		var timer = get_tree().create_timer(Globals.COLLECTION_EFFECT_LIFESPAN)
		timer.timeout.connect(minesweeper_collection_complete)
	else:
		minesweeper_collection_complete()

## Function for instantiating BombView scenes. 
func create_bomb_view(tile: BoardTile) -> BombEntityView:
	if !tile.has_bomb():
		push_error("called create_bomb_view with a tile that does not have a bomb. Returning without creating a bomb")
	
	var bomb_entity: BombEntityModel =  BoardTileController.INSTANCE.get_entity(tile.get_entity_id())
	var bomb_prefab: PackedScene = BombData.get_bomb_data(bomb_entity.get_bomb_type()).view_scene
	
	var bomb_view = bomb_prefab.instantiate()
	get_tree().root.add_child(bomb_view)
	bomb_view.init(bomb_entity)

	bomb_view.global_position = tile.get_global_position()
	bomb_views_by_entity_id[bomb_entity.get_id()] = bomb_view
	
	return bomb_view

func on_building_placed():
	if state == State.Moving:
		return
	if state != State.Placing:
		push_error("Invalid state when building placed!")
		return
	
	building_placed.emit()

func on_building_right_click_cancel():
	building_right_click_cancelled.emit()

func on_cancel_building_placement():
	state = State.Build
	if current_placing_instance != null:
		current_placing_instance.cancel_placement()
		current_placing_instance = null

func on_confirm_building_placement() -> void:
	current_placing_instance.place()
	current_placing_instance.confirm_placement()
	current_placing_instance.on_selected.connect(on_building_selected)
	total_building_count += 1
	
	var type := current_placing_instance.type
	var entity_id := current_placing_instance.get_model().get_id()
	
	building_views_by_entity_id[entity_id] = current_placing_instance
	
	SoundManager.play_building_placement_sound()
	
	if type == BuildingData.Type.WORKSHOP:
		workshop_placed.emit()
	elif type == BuildingData.Type.WONDER:
		wonder_placed.emit()
	elif type == BuildingData.Type.STAIRCASE:
		stairs_placed = true
	
	state = State.Build

func on_building_selected(building: BuildingEntityView):
	if state == State.Deactivated:
		return
	
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
	assert(state == State.Selected)
	assert(selected_building != null)
	
	var building: BuildingEntityView = selected_building
	var entity_id := building.get_model().get_id()
	var type := building.type
	building_views_by_entity_id.erase(entity_id)
	
	# updates the UI
	deselect_building()
	building.destroy()
	
	state = State.Build
	
	if type == BuildingData.Type.WORKSHOP:
		workshop_destroyed.emit()

func move_selected_building():
	assert(state == State.Selected)
	assert(selected_building != null)

	var building: BuildingEntityView = selected_building
	var data := building.get_building_data()
	var entity_id := building.get_model().get_id()

	state = State.Moving
	moving_building_origin_cell_pos = building.get_model().get_bounding_cell_rect().position
	
	selected_building.start_move()

func confirm_selected_building_move():
	assert(state == State.Moving)
	assert(selected_building != null)
	
	var building: BuildingEntityView = selected_building
	var data := building.get_building_data()
	var entity_id := building.get_model().get_id()
	
	state = State.Selected
	building.confirm_placement()
	
	# Update UI
	deselect_building()
	
func cancel_selected_building_move():
	if state != State.Moving:
		push_error("Tried to cancel building move while board not in moving state")
		return
	
	var building: BuildingEntityView = selected_building
	state = State.Selected
	var type := building.type
	var data := building.get_building_data()
	var entity_id := building.get_model().get_id()
	var model := building.get_model()
	
	model.move(Rect2i(moving_building_origin_cell_pos, model.get_bounding_cell_rect().size))
	building.match_model_position()
	selected_building.confirm_placement()
	deselect_building()

func collect_resources():
	print("beginning collection")
	state = State.Complete
	
	var collected_count := 0
	for id in building_views_by_entity_id.keys():
		var building: BuildingEntityView = building_views_by_entity_id[id]
		var data := building.get_building_data()
		if !data.grants_resources():
			continue
		
		print("grants resources")
		
		var type := building.type
		var model: BaseBuildingEntityModel = building.get_model()
		
		var occupied_tiles := model.get_occupied_tiles()
		var collection_problems := model.get_collection_problems()
		if collection_problems.is_empty():
			print("no collection problem")
			model.collect()
			building_views_by_entity_id[model.get_id()].play_collection_animation(collected_count)
			collected_count += 1
	
	
	if collected_count > 0:
		var timer = get_tree().create_timer(Globals.COLLECTION_EFFECT_LIFESPAN)
		timer.timeout.connect(building_collection_complete)
		SoundManager.play_collection()
	else:
		building_collection_complete()

func building_collection_complete():
	on_building_collection_complete.emit()

func minesweeper_collection_complete():
	state = State.Build
	
	for label in number_labels:
		label.queue_free()
	
	for flag in flags_by_cell_pos.values():
		flag.queue_free()
	
	on_minesweeper_collection_complete.emit()

func clear_tile(tile: BoardTile):
	if tile.is_flagged:
		flags += 1
		print("bombs found: ", bombs_found)
		tile.toggle_flag()
	uncover_tile(tile)
	tilemap.update_terrain(get_boundaries_rect())

func uncover_tile(tile: BoardTile, distance: int = 0, max_depth: int = -1, trigger_mines: bool = true) -> void:
	tile.uncover()
	tilemap.remove_tile(tile.cell_position, get_boundaries_rect(), distance)
	tiles_uncovered += 1
	distance += 1
	
	if tile.has_bomb() && trigger_mines:
		var bomb_view : BombEntityView = create_bomb_view(tile)
		bomb_view.animation_complete.connect(on_bomb_animation_complete)
		bomb_view.play_explode_animation()
		mine_exploded = true
		return
	
	if tile.is_flagged():
		flags += 1
		tile.destroy_flag()
	
	var adjacent_tiles: Array[BoardTile] = BoardTileController.INSTANCE.get_adjacent_tiles(tile, get_boundaries_rect())
	
	var adjacent_bombs = 0
	for adjacent_tile in adjacent_tiles:
		if adjacent_tile.has_bomb():
			adjacent_bombs += 1
	
	if adjacent_bombs > 0:
		create_number_label(tile, adjacent_bombs)
	elif max_depth < 0 || distance <= max_depth:
		for adjacent_tile in adjacent_tiles:
			if adjacent_tile.is_covered() && !tile.has_bomb():
				uncover_tile(adjacent_tile, distance, max_depth, trigger_mines)

func create_number_label(tile: BoardTile, bomb_count: int) -> void:
	if state != State.Play:
		return
	if bomb_count > 0:
		var label = number_label_prefab.instantiate()
		get_tree().root.add_child(label)
		label.global_position = tile.get_global_position()
		label.set_number(bomb_count)
		number_labels.append(label)


func explode_mine():
	# TODO: play an animation and emit signal when it finishes
	SoundManager.play_explosion_sound()

func on_bomb_animation_complete():
	mine_animation_complete.emit()

func _on_flag_toggled(cell_pos: Vector2i):
	if !contains_cell_position(cell_pos):
		return
	var tile: BoardTile = BoardTileController.INSTANCE.get_tile_at_cell_position(cell_pos)
	if tile.is_uncovered():
		return
	
	if tile.is_flagged():
		flags += 1
	elif flags > 0:
		flags -= 1
	else:
		return
	

	
	if !tile.is_flagged() && tile.has_bomb():
		bombs_found += 1
	elif tile.is_flagged() && tile.has_bomb():
		bombs_found -= 1
	
	if !tile.is_flagged():
		SoundManager.play_flag_sound()
		create_flag(cell_pos)
	else:
		destroy_flag(cell_pos)
	
	print("bombs found: ", bombs_found)
	tile.toggle_flag()
	
	tile_flagged_event_complete.emit()

func create_flag(cell_pos: Vector2i) -> void:
	var flag = flag_prefab.instantiate()
	get_tree().root.add_child(flag)
	flag.global_position = Globals.cell_to_global(cell_pos)
	flags_by_cell_pos[cell_pos] = flag

func destroy_flag(cell_pos: Vector2i) -> void:
	var flag = flags_by_cell_pos[cell_pos]
	flag.queue_free()
	flags_by_cell_pos.erase(cell_pos)

func are_all_buildings_being_exploited() -> bool:
	for building in building_views_by_entity_id.values():
		var view: BuildingEntityView = building
		var collection_problems = view.get_model().get_collection_problems()
		if collection_problems.size() > 0:
			return false
	return true

func is_cleared():
	return tiles_uncovered + bombs_found == rows * columns

func lock():
	state = State.Locked

func destroy():
	for label in number_labels:
		label.queue_free()
	
	for flag in flags_by_cell_pos.values():
		flag.queue_free()
	
	for bomb_view in bomb_views_by_entity_id.values():
		bomb_view.queue_free()
	
	for building_view in building_views_by_entity_id.values():
		building_view.queue_free()
	
	queue_free()
	
func deactivate():
	deselect_building()
	state = State.Deactivated
	tilemap.uncovered.disconnect(_on_tile_uncovered)
	tilemap.flag_toggled.disconnect(_on_flag_toggled)

func activate():
	state = State.Play
	tilemap.uncovered.connect(_on_tile_uncovered)
	tilemap.flag_toggled.connect(_on_flag_toggled)

func is_locked():
	return state == State.Locked

func get_center_global_position() -> Vector2:
	return position + (get_size_global_position() / 2) 

func get_size_global_position() -> Vector2:
	return Vector2(columns * Globals.TILE_SIZE, rows * Globals.TILE_SIZE)

func contains_cell_position(pos: Vector2i) -> bool:
	return get_boundaries_rect().has_point(pos)

func get_boundaries_rect() -> Rect2i:
	return Rect2i(tilemap_origin_cell_pos, Vector2i(columns, rows))
