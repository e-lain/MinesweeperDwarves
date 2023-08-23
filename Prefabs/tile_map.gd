extends TileMap

signal uncovered(cell_pos: Vector2i)
signal flag_toggled(cell_pos: Vector2i)

func _input(event):
	if event is InputEventMouseButton:
		if !get_parent().build_mode:
			event = make_input_local(event)
			var mouse_pos = event.position
			var cell_pos = local_to_map(mouse_pos)
			if get_cell_tile_data(0, cell_pos) == null:
				return
			if event.is_action_pressed("left_click"):
				uncovered.emit(cell_pos)
			if event.is_action_pressed("right_click"):
				flag_toggled.emit(cell_pos)
