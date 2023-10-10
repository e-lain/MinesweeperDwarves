class_name BiomeData

enum Type {
	DEFAULT,
	LAVA
}

static func get_buildings(tier: int):
	match tier:
		1:
			return data[Type.DEFAULT].buildings
		2: 
			return data[Type.LAVA].buildings

static func get_bombs(tier: int):
	match tier:
		1:
			return data[Type.DEFAULT].bombs
		2:
			return data[Type.LAVA].bombs

static var data = {
	Type.DEFAULT: {
		"type": Type.DEFAULT,
		"name": "The Mines",
		"tier": 1,
		"buildings": [BuildingData.Type.STAIRCASE, BuildingData.Type.MINECART, BuildingData.Type.HOUSE, BuildingData.Type.QUARRY, BuildingData.Type.WORKSHOP],
		"bombs": [BombData.Type.DEFAULT]
	},
	Type.LAVA: {
		"type": Type.LAVA,
		"name": "The Volcano",
		"tier": 2,
		"buildings": [BuildingData.Type.LAVA, BuildingData.Type.FORGE],
		"bombs": [BombData.Type.DEFAULT, BombData.Type.LAVA]
	}
}
