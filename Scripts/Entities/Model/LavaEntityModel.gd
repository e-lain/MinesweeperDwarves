class_name LavaEntityModel extends BombEntityModel

var _connection_graph_id: int = -1

func set_new_connection_graph_id(id: int) -> void:
	_connection_graph_id = id
	
func get_connection_graph_id() -> int:
	return _connection_graph_id

func place(bounding_cell_rect: Rect2i) -> void:
	super(bounding_cell_rect)
	LavaConnectionController.INSTANCE.add_lava_connection_entity(self, true)

func remove():
	LavaConnectionController.INSTANCE.remove_lava_connection_entity(self, true)
	super()
