class_name BuildingData

enum Type {
	HOUSE,
	QUARRY,
	STAIRCASE,
	WORKSHOP,
	WONDER,
	MINECART,
	LAVA,
	FORGE
}

static var data = {
	Type.HOUSE: {
		"type": Type.HOUSE,
		"name": "House",
		"description": "Gain 2 Population",
		"stone_cost": 10,
		"population_cost": -2,
		"steel_cost": 0,
		"size": 2,
		"icon_path": "res://Assets/Buildings/HouseBuildingDownscaled.png"
	},
	Type.QUARRY: {
		"type": Type.QUARRY,
		"name": "Quarry",
		"description": "Gain 4 Stone",
		"stone_cost": -4,
		"population_cost": 0,
		"steel_cost": 0,
		"size": 2,
		"icon_path": "res://Assets/Buildings/MiningBuildingDownscale.png"
	},
	Type.STAIRCASE: {
		"type": Type.STAIRCASE,
		"name": "Staircase",
		"description": "Opens next floor and allows placing other buildings",
		"stone_cost": 0,
		"population_cost": 0,
		"steel_cost": 0,
		"size": 1,
		"icon_path": "res://Assets/Buildings/StairsDown.png"
	},
	Type.WORKSHOP: {
		"type": Type.WORKSHOP,
		"name": "Engineer's Workshop",
		"description": "Gain Active Ability Charge",
		"stone_cost": 5,
		"population_cost": 1,
		"steel_cost": 0,
		"size": 3,
		"icon_path": "res://Assets/Buildings/EngineerWorkshopBuildingDownscale.png"
	},
	Type.WONDER: {
		"type": Type.WONDER,
		"name": "Beer Hall",
		"description": "Win the Game",
		"stone_cost": 100,
		"population_cost": 5,
		"steel_cost": 0,
		"size": 5,
		"icon_path": "res://Assets/UI/WonderUIIcon.png"
	},
	Type.MINECART: {
		"type": Type.MINECART,
		"name": "Minecart",
		"description": "Collect Resources of Adjacent Buildings",
		"stone_cost": 0,
		"population_cost": 0,
		"steel_cost": 1,
		"size": 1,
		"icon_path": "res://Assets/Buildings/minecart downscaled.png"
	},
	Type.LAVA: {
		"type": Type.LAVA,
		"name": "Lava Moat",
		"description": "Needs to be adjacent to build a Forge. Can only connect to other Lava tiles",
		"stone_cost": 3,
		"population_cost": 0,
		"steel_cost": 0,
		"size": 1,
		"icon_path": "res://Assets/Buildings/lava.png"
	},
	Type.FORGE: {
		"type": Type.FORGE,
		"name": "Forge",
		"description": "Needs to be built adjacent to a Lava Moat. Gain ___",
		"stone_cost": 5,
		"population_cost": 0,
		"steel_cost": 1,
		"size": 1,
		"icon_path": "res://Assets/Buildings/forge.png"
	}
}
