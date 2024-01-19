class_name BiomeData

enum Type {
	DEFAULT = 1,
	LAVA
}

static func get_buildings(tier: int):
	match tier:
		1:
			return data[Type.DEFAULT].buildings
		2: 
			return data[Type.LAVA].buildings
		_:
			return []

static func get_bombs(tier: int):
	match tier:
		1:
			return data[Type.DEFAULT].bombs
		2:
			return data[Type.LAVA].bombs
		_:
			return []

static func get_resources(tier: int):
	if !data.has(tier):
		return []
	else:
		var tier_data = data[tier]
		return [] if !tier_data.has("resources") else tier_data["resources"]

static var data = {
	Type.DEFAULT: {
		"type": Type.DEFAULT,
		"name": "The Mines",
		"tier": 1,
		"buildings": [BuildingData.Type.STAIRCASE, BuildingData.Type.MINECART, BuildingData.Type.HOUSE, BuildingData.Type.QUARRY, BuildingData.Type.WORKSHOP],
		"bombs": [BombData.Type.DEFAULT],
		"resources": [ResourceData.Resources.STONE, ResourceData.Resources.POPULATION, ResourceData.Resources.STEEL]
	},
	Type.LAVA: {
		"type": Type.LAVA,
		"name": "The Volcano",
		"tier": 2,
		"buildings": [BuildingData.Type.LAVA, BuildingData.Type.FORGE],
		"bombs": [BombData.Type.DEFAULT, BombData.Type.LAVA],
		"resources": [ResourceData.Resources.SLEDGEHAMMER]
	}
}
