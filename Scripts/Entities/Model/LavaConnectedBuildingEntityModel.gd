class_name LavaConnectedBuildingEntityModel extends BaseBuildingEntityModel
## Entity Model which keeps track of how many lava source tiles it is orthogonally connected to, either directly or through other lava connected tiles 
##
## This is NOT intended to be used by buildings which have an adjacency requirement to lava, but rather for lava moats

var _connected_lava_sources: Array[int] = []

func get_connected_lava_sources_count() -> int:
	return _connected_lava_sources.size()

func connect_lava_source(source_id: int) -> void:
	_connected_lava_sources.append(source_id)
	
func disconnect_lava_source(source_id: int) -> void:
	_connected_lava_sources.erase(source_id)
