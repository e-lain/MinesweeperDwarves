class_name MinecartTileRequirement extends TileRequirement

func test(test_tile: BoardTile) -> bool:
	var entity_id: int = test_tile.get_entity_id()
	if entity_id < 0:
		return false
	
	var tile_entity: BoardEntityModel = BoardTileController.INSTANCE.get_entity(entity_id)
	
	if !(tile_entity is BaseBuildingEntityModel):
		return false
	
	return (tile_entity as BaseBuildingEntityModel).get_type() == BuildingData.Type.MINECART
