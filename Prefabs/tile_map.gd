extends TileMap

signal uncovered(cell_pos: Vector2i)
signal flag_toggled(cell_pos: Vector2i)
signal destroyed(cell_pos: Vector2i)

const mined_tile_prefab: PackedScene = preload("res://Prefabs/MinedTile.tscn")

@export var default_behavior:bool = true


var tap_start_time
var tap_start_pos

var changeset: Dictionary

var active: bool = true

func fill(size_x: int, size_y: int, tier: int) -> Array:
	var tiles = []
	
	var update = {}
	for c in size_x:
		tiles.append([])
		for r in size_y:
			var t = BoardTile.new()
			t.label_parent = self
			var cell_pos = Vector2i(c, r)
			t.cell_position = cell_pos
			tiles[c].append(t)
			update[cell_pos] = 0
	
	changeset = BetterTerrain.create_terrain_changeset(self, 0, update)

	return tiles

func remove_tile(pos: Vector2i, origin_distance: int = 0) -> void:
	var tile_instance = mined_tile_prefab.instantiate()
	add_child(tile_instance)
	
	var atlas_coords = get_cell_atlas_coords(0, pos)
	tile_instance.init(map_to_local(pos), atlas_coords, pos, origin_distance)
	BetterTerrain.set_cell(self, 0, pos, -1)
	BetterTerrain.update_terrain_area(self, 0, Rect2i(max(0, pos.x - 2), max(0, pos.y - 2), 4, 4))

func set_lava_source(pos: Vector2i) -> void:
	BetterTerrain.set_cell(self, 0, pos, 2)
	BetterTerrain.update_terrain_area(self, 0, Rect2i(max(0, pos.x - 2), max(0, pos.y - 2), 4, 4))

func set_lava_moat(pos: Vector2i) -> void:
	BetterTerrain.set_cell(self, 0, pos, 3)
	BetterTerrain.update_terrain_area(self, 0, Rect2i(max(0, pos.x - 2), max(0, pos.y - 2), 4, 4))

func update_shadows(size_x: int, size_y: int) -> void:
	var used_cells = get_used_cells_by_id(0, 0)
	var occupied_tiles = {}
	var update = {}
	
	for pos in used_cells:
		occupied_tiles[pos] = null
	var unused_cells = []
	for y in size_y:
		for x in size_x:
			var cell = Vector2i(x,y)
			if !occupied_tiles.has(cell):
				unused_cells.append(cell)
	
	clear_layer(1)
	set_cells_terrain_connect(1, unused_cells, 0, 1)

func _process(delta):
	if  BetterTerrain.is_terrain_changeset_ready(changeset):
		BetterTerrain.apply_terrain_changeset(changeset)
		changeset = {}
		
	if !active:
		return
	
	if DragOrZoomEventManager.long_tap_started && Time.get_ticks_msec() - tap_start_time > SettingsController.LONG_TAP_DELAY_MS  && !DragOrZoomEventManager.drag_or_zoom_happening():
		DragOrZoomEventManager.long_tap_started = false
		DragOrZoomEventManager.long_tap_occurred = true
			
		if PlatformUtil.isMobile():
			Input.vibrate_handheld(100)
		flag_toggled.emit(tap_start_pos)
	

#	var used_cells = get_used_cells(0)
#	if used_cells.size() > 0:
#		get_cell_tile_data(0, used_cells[0]).material.set_shader_parameter("global_transform", get_global_transform())


func _unhandled_input(event):
	if !default_behavior || !active:
		return
	
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click") && get_parent().clearing_tile:
			event = make_input_local(event)
			var mouse_pos = event.position
			var cell_pos = local_to_map(mouse_pos)
			destroyed.emit(cell_pos)
		if get_parent().state == Board.State.Play:
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
		
