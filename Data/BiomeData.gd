class_name BiomeData

enum Type {
	DEFAULT = 1,
	LAVA
}

static func get_buildings(tier: int) -> Array[BuildingData.Type]:
	var result :Array[BuildingData.Type]
	match tier:
		1:
			result.assign(data[Type.DEFAULT]["buildings"])
		2: 
			result.assign(data[Type.LAVA]["buildings"])
		_:
			return []
	return result

static func get_bombs(tier: int) -> Array[BombData.Type]:
	var result: Array[BombData.Type]
	match tier:
		1:
			result.assign(data[Type.DEFAULT]["bombs"])
		2:
			result.assign(data[Type.LAVA]["bombs"])
		_:
			return []
	return result 

static func get_resources(tier: int) -> Array[ResourceData.Resources]:
	if !data.has(tier):
		return []
	else:
		var tier_data = data[tier]
		if !tier_data.has("resources"):
			return []
		
		var result: Array[ResourceData.Resources]
		result.assign(tier_data["resources"])
		return result

static var data = {
	Type.DEFAULT: {
		"type": Type.DEFAULT,
		"name": "The Mines",
		"tier": 1,
		"buildings": [BuildingData.Type.STAIRCASE, BuildingData.Type.MINECART, BuildingData.Type.HOUSE, BuildingData.Type.QUARRY, BuildingData.Type.WORKSHOP],
		"bombs": [BombData.Type.Default],
		"resources": [ResourceData.Resources.STONE, ResourceData.Resources.POPULATION, ResourceData.Resources.STEEL]
	},
	Type.LAVA: {
		"type": Type.LAVA,
		"name": "The Volcano",
		"tier": 2,
		"buildings": [BuildingData.Type.LAVA, BuildingData.Type.FORGE, BuildingData.Type.GLASSWORKS],
		"bombs": [BombData.Type.Default, BombData.Type.Lava],
		"resources": [ResourceData.Resources.SLEDGEHAMMER]
	}
}
