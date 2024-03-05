class_name LavaSourceTileRequirement extends TileRequirement

func test(test_tile: BoardTile) -> bool:
	if !test_tile.has_entity():
		return false
	
	return BoardTileController.INSTANCE.get_entity(test_tile.get_entity_id()) is LavaEntityModel
