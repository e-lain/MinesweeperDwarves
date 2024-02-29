class_name WorkshopTileRequirement extends TileRequirement

## "Virtual" function for testing if a tile requirement is met
func test(test_tile: BoardTile):
	if test_tile.get_entity_id() < 0:
		return false
		
	var entity: BoardEntityModel = BoardTileController.INSTANCE.get_entity(test_tile.get_entity_id())
	if !(entity is BaseBuildingEntityModel):
		return false
		
	return (entity as BaseBuildingEntityModel).get_type() == BuildingData.Type.WORKSHOP
