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
		"costs": {
			ResourceData.Resources.STONE: 10,
			ResourceData.Resources.POPULATION: -2,
		},
		"size": 2,
		"icon_path": "res://Assets/Buildings/HouseBuildingDownscaled.png"
	},
	Type.QUARRY: {
		"type": Type.QUARRY,
		"name": "Quarry",
		"description": "Gain 4 Stone",
		"costs": {
			ResourceData.Resources.STONE: -4,
		},
		"size": 2,
		"icon_path": "res://Assets/Buildings/MiningBuildingDownscale.png"
	},
	Type.STAIRCASE: {
		"type": Type.STAIRCASE,
		"name": "Staircase",
		"description": "Opens next floor and allows placing other buildings",
		"size": 1,
		"icon_path": "res://Assets/Buildings/StairsDown.png"
	},
	Type.WORKSHOP: {
		"type": Type.WORKSHOP,
		"name": "Engineer's Workshop",
		"description": "Gain Active Ability Charge",
		"costs": {
			ResourceData.Resources.STONE: 5,
			ResourceData.Resources.POPULATION: 1,
		},
		"size": 3,
		"icon_path": "res://Assets/Buildings/EngineerWorkshopBuildingDownscale.png"
	},
	Type.WONDER: {
		"type": Type.WONDER,
		"name": "Beer Hall",
		"description": "Win the Game",
		"costs": {
			ResourceData.Resources.STONE: 100,
			ResourceData.Resources.POPULATION: 5,
		},
		"size": 5,
		"icon_path": "res://Assets/UI/WonderUIIcon.png"
	},
	Type.MINECART: {
		"type": Type.MINECART,
		"name": "Minecart",
		"description": "Collect Resources of Adjacent Buildings",
		"costs": {
			ResourceData.Resources.STEEL: 1,
		},
		"size": 1,
		"icon_path": "res://Assets/Buildings/minecart downscaled.png"
	},
	Type.LAVA: {
		"type": Type.LAVA,
		"name": "Lava Moat",
		"description": "Needs to be adjacent to build a Forge. Can only connect to other Lava tiles",
		"costs": {
			ResourceData.Resources.STONE: 3,
		},
		"size": 1,
		"icon_path": "res://Assets/TempLavaMoat.png" # TODO: Replace this with the appropriate texture when available
	},
	Type.FORGE: {
		"type": Type.FORGE,
		"name": "Forge",
		"description": "Needs to be built adjacent to a Lava Moat. Gain ___",
		"costs": {
			ResourceData.Resources.STONE: 5,
			ResourceData.Resources.STEEL: 1,
		},
		"size": 1,
		"icon_path": "res://Assets/Buildings/forge.png"
	}
}

static func get_costs(building_type: Type) -> Dictionary:
	var building_data: Dictionary = data[building_type]
	return {} if !building_data.has("costs") else building_data["costs"]
	
static func get_cost(building_type: Type, resource_type: ResourceData.Resources) -> int:
	var costs = get_costs(building_type)
	return 0 if !costs.has(resource_type) else costs[resource_type]
