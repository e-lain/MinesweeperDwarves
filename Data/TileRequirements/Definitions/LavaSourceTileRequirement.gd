class_name LavaSourceTileRequirement extends TileRequirement

func test(test_tile: BoardTile) -> bool:
	return test_tile.lava_uid != null
