extends TileMap
class_name SharedTileMap

signal uncovered(cell_pos: Vector2i)
signal flag_toggled(cell_pos: Vector2i)
signal destroyed(cell_pos: Vector2i)

const mined_tile_prefab: PackedScene = preload("res://Prefabs/MinedTile.tscn")
const bounds_rect_changeset_key = "bounds_rect"
const layer_changeset_key = "layer"


@export var default_behavior:bool = true


var tap_start_time
var tap_start_pos

var changeset: Array[Dictionary] = []

func fill(bounds_rect: Rect2i) -> void:
	var update = {}
	for c in bounds_rect.size.x:
		for r in bounds_rect.size.y:
			var cell_pos = bounds_rect.position + Vector2i(c, r)
			update[cell_pos] = 0
	
	var fill_changeset = BetterTerrain.create_terrain_changeset(self, 0, update)
	fill_changeset[bounds_rect_changeset_key] = bounds_rect
	changeset.append(fill_changeset)

func remove_tile(pos: Vector2i, bounds_rect: Rect2i, origin_distance: int = 0) -> void:
	var tile_instance = mined_tile_prefab.instantiate()
	add_child(tile_instance)
	
	var atlas_coords := get_cell_atlas_coords(0, pos)
	tile_instance.init(map_to_local(pos), atlas_coords, pos, origin_distance)

	BetterTerrain.set_cell(self, 0, pos, -1)

func set_lava_source(pos: Vector2i, bounds_rect: Rect2i) -> void:
	BetterTerrain.set_cell(self, 0, pos, 2)
	update_terrain(bounds_rect)

func set_lava_moat(pos: Vector2i, bounds_rect: Rect2i) -> void:
	BetterTerrain.set_cell(self, 0, pos, 3)
	update_terrain(bounds_rect)

func update_terrain(bounds: Rect2i) -> void:
	bounds.size += Vector2i(2, 2)
	bounds.position -= Vector2i.ONE
	BetterTerrain.update_terrain_area(self, 0, bounds, true)

func _process(delta):
	if Input.is_action_just_pressed("Test_1"):
		update_terrain(get_used_rect())
	
	while(!changeset.is_empty() && BetterTerrain.is_terrain_changeset_ready(changeset[0])):
		var first_change_set = changeset.pop_front()
		BetterTerrain.apply_terrain_changeset(first_change_set)
		if first_change_set.has(bounds_rect_changeset_key):
			update_terrain(first_change_set[bounds_rect_changeset_key])
	
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
		
