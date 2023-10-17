extends TileMap

signal uncovered(cell_pos: Vector2i)
signal flag_toggled(cell_pos: Vector2i)
signal destroyed(cell_pos: Vector2i)

@export var default_behavior:bool = true


var tap_start_time
var tap_start_pos

func _process(delta):
	if DragOrZoomEventManager.long_tap_started && Time.get_ticks_msec() - tap_start_time > SettingsController.LONG_TAP_DELAY_MS  && !DragOrZoomEventManager.drag_or_zoom_happening():
		DragOrZoomEventManager.long_tap_started = false
		DragOrZoomEventManager.long_tap_occurred = true
		flag_toggled.emit(tap_start_pos)

func _unhandled_input(event):
	if !default_behavior:
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
		
