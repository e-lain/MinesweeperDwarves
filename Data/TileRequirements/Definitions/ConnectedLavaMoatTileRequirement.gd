class_name ConnectedLavaMoatTileRequirement extends TileRequirement

@export var connection_count_minimum: int = 1

func test(test_tile: BoardTile) -> bool:
	var entity_id: int = test_tile.get_entity_id()
	if entity_id < 0:
		return false
	
	var tile_entity: BoardEntityModel = BoardTileController.INSTANCE.get_entity(entity_id)
	
	if !(tile_entity is LavaConnectedBuildingEntityModel):
		return false
	
	var lava_connected := tile_entity as LavaConnectedBuildingEntityModel
	
	return lava_connected.get_type() == BuildingData.Type.LAVA && lava_connected.get_connected_lava_sources_count() >= connection_count_minimum

