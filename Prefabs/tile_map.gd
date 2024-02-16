extends TileMap
class_name SharedTileMap

signal uncovered(cell_pos: Vector2i)
signal flag_toggled(cell_pos: Vector2i)
signal destroyed(cell_pos: Vector2i)

const mined_tile_prefab: PackedScene = preload("res://Prefabs/MinedTile.tscn")

@export var default_behavior:bool = true


var tap_start_time
var tap_start_pos

var changeset: Array[Dictionary] = []

func fill(origin_cell_pos: Vector2i, size_x: int, size_y: int, tier: int) -> Array:
	var tiles = []
	
	var update = {}
	for c in size_x:
		tiles.append([])
		for r in size_y:
			var t = BoardTile.new()
			t.label_parent = self
			var cell_pos = origin_cell_pos + Vector2i(c, r)
			t.cell_position = cell_pos
			tiles[c].append(t)
			update[cell_pos] = 0
	
	changeset.append(BetterTerrain.create_terrain_changeset(self, 0, update))

	return tiles

func remove_tile(pos: Vector2i, origin_distance: int = 0) -> void:
	var tile_instance = mined_tile_prefab.instantiate()
	add_child(tile_instance)
	
	var atlas_coords = get_cell_atlas_coords(0, pos)
	tile_instance.init(map_to_local(pos), atlas_coords, pos, origin_distance)
	var update = {pos: -1}
	changeset.append(BetterTerrain.create_terrain_changeset(self, 0, update))

func set_lava_source(pos: Vector2i) -> void:
	var update = {pos: 2}
	changeset.append(BetterTerrain.create_terrain_changeset(self, 0, update))

func set_lava_moat(pos: Vector2i) -> void:
	var update = {pos: 3}
	changeset.append(BetterTerrain.create_terrain_changeset(self, 0, update))

func update_shadows() -> void:
	var used_cells = get_used_cells_by_id(0, 0)
	var occupied_tiles = {}
	var update = {}
	
	var used_rect = get_used_rect()
	used_rect.position -= Vector2i(10, 10)
	used_rect.size += Vector2i(20, 20)
	
	for pos in used_cells:
		occupied_tiles[pos] = null
	var unused_cells = []
	for y in used_rect.size.y:
		for x in used_rect.size.x:
			var cell = used_rect.position + Vector2i(x,y)
			if !occupied_tiles.has(cell):
				unused_cells.append(cell)
				update[cell] = 1
			else:
				update[cell] = -1
	
	changeset.append(BetterTerrain.create_terrain_changeset(self, 1, update))

func _process(delta):
	while(!changeset.is_empty() && BetterTerrain.is_terrain_changeset_ready(changeset[0])):
		var first_change_set = changeset.pop_front()
		BetterTerrain.apply_terrain_changeset(first_change_set)
		if changeset.is_empty() && first_change_set["layer"] != 1:
			update_shadows()
	
	if DragOrZoomEventManager.long_tap_started && Time.get_ticks_msec() - tap_start_time > SettingsController.LONG_TAP_DELAY_MS  && !DragOrZoomEventManager.drag_or_zoom_happening():
		DragOrZoomEventManager.long_tap_started = false
		DragOrZoomEventManager.long_tap_occurred = true
			
		if PlatformUtil.isMobile():
			Input.vibrate_handheld(100)
		flag_toggled.emit(tap_start_pos)

func _unhandled_input(event):
	if !default_behavior:
		return
	
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click") && get_parent().get_current_board().clearing_tile:
			event = make_input_local(event)
			var mouse_pos = event.position
			var cell_pos = local_to_map(mouse_pos)
			destroyed.emit(cell_pos)
		if get_parent().get_current_board().state == Board.State.Play:
			event = make_input_local(event)
			var mouse_pos = event.position
			var cell_pos = local_to_map(mouse_pos)
			if get_cell_tile_data(0, cell_pos) == null:
				return
			if event.is_action_pressed("left_click") && !DragOrZoomEventManager.drag_or_zoom_happening():
				DragOrZoomEventManager.long_tap_started = true
				tap_start_time = Time.get_ticks_msec()
				tap_start_pos = cell_pos
			

			if event.is_action_released("left_click") && !DragOrZoomEventManager.drag_or_zoom_happening():
				DragOrZoomEventManager.long_tap_started = false
				uncovered.emit(cell_pos)
			elif event.is_action_released("right_click") && !DragOrZoomEventManager.drag_or_zoom_happening():
				flag_toggled.emit(cell_pos)
		
