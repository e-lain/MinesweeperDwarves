class_name BuildingData

enum Type {
	HOUSE,
	QUARRY,
	STAIRCASE,
	WORKSHOP,
	WONDER
}

static var data = {
	Type.HOUSE: {
		"type": Type.HOUSE,
		"name": "House",
		"description": "Gain 2 Population",
		"stone_cost": 10,
		"population_cost": -2,
		"size": 2,
		"icon_path": "res://Assets/Buildings/HouseBuildingDownscaled.png"
	},
	Type.QUARRY: {
		"type": Type.QUARRY,
		"name": "Quarry",
		"description": "Gain 4 Stone",
		"stone_cost": -4,
		"population_cost": 0,
		"size": 2,
		"icon_path": "res://Assets/Buildings/MiningBuildingDownscale.png"
	},
	Type.STAIRCASE: {
		"type": Type.STAIRCASE,
		"name": "Staircase",
		"description": "Descend to next floor",
		"stone_cost": 0,
		"population_cost": 0,
		"size": 1,
		"icon_path": "res://Assets/Buildings/StairsDown.png"
	},
	Type.WORKSHOP: {
		"type": Type.WORKSHOP,
		"name": "Engineer's Workshop",
		"description": "Gain Ability to Destroy Tiles ",
		"stone_cost": 50,
		"population_cost": 1,
		"size": 3,
		"icon_path": "res://Assets/Buildings/EngineerWorkshopBuildingDownscale.png"
	},
	Type.WONDER: {
		"type": Type.WONDER,
		"name": "Beer Hall",
		"description": "Win the Game",
		"stone_cost": 100,
		"population_cost": 5,
		"size": 5,
		"icon_path": "res://Assets/Buildings/EngineerWorkshopBuildingDownscale.png"
	},
}
