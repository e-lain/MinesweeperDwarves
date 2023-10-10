class_name BiomeData

enum Type {
	DEFAULT,
	LAVA
}

static func get_buildings(tier: int):
	match tier:
		1:
			return data[Type.DEFAULT].buildings
		2: return data[Type.LAVA].buildings

static var data = {
	Type.DEFAULT: {
		"type": Type.DEFAULT,
		"name": "The Mines",
		"tier": 1,
		"buildings": [BuildingData.Type.STAIRCASE, BuildingData.Type.MINECART, BuildingData.Type.HOUSE, BuildingData.Type.QUARRY, BuildingData.Type.WORKSHOP]
	},
	Type.LAVA: {
		"type": Type.LAVA,
		"name": "The Volcano",
		"tier": 2,
		"buildings": [BuildingData.Type.LAVA, BuildingData.Type.FORGE]
	}
}
