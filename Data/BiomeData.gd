class_name BiomeData

enum Type {
	DEFAULT,
	LAVA
}

static var data = {
	Type.DEFAULT: {
		"type": Type.DEFAULT,
		"name": "The Mines",
		"tier": 0,
		"buildings": [BuildingData.Type.STAIRCASE, BuildingData.Type.MINECART, BuildingData.Type.HOUSE, BuildingData.Type.QUARRY, BuildingData.Type.WORKSHOP]
	},
	Type.LAVA: {
		"type": Type.LAVA,
		"name": "The Volcano",
		"tier": 2,
		"buildings": [BuildingData.Type.LAVA, BuildingData.Type.FORGE]
	}
}
