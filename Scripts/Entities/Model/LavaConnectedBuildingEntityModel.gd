class_name LavaConnectedBuildingEntityModel extends BaseBuildingEntityModel
## Entity Model which keeps track of how many lava source tiles it is orthogonally connected to, either directly or through other lava connected tiles 
##
## This is NOT intended to be used by buildings which have an adjacency requirement to lava, but rather for lava moats

## An array containing the entity IDs of each connected lava source
var _connection_graph_id: int = -1

func set_new_connection_graph_id(id: int) -> void:
	_connection_graph_id = id
	
func get_connection_graph_id() -> int:
	return _connection_graph_id

func get_connected_lava_sources_count() -> int:
	if _connection_graph_id < 0:
		return 0
	return LavaConnectionController.INSTANCE.get_connection_graph(_connection_graph_id).lava_source_entity_ids.size()

func place(bounding_cell_rect: Rect2i) -> void:
	super(bounding_cell_rect)
	LavaConnectionController.INSTANCE.add_lava_connection_entity(self, false)

func remove() -> void:
	LavaConnectionController.INSTANCE.remove_lava_connection_entity(self, false)
	super()

