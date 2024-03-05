class_name BuildingData extends RefCounted

static var INSTANCE: BuildingData

const building_resources_path := "res://Data/Buildings/Resources/"

enum Type {
	HOUSE,
	QUARRY,
	STAIRCASE,
	WORKSHOP,
	WONDER,
	MINECART,
	LAVA,
	FORGE,
	GLASSWORKS
}

var _data: Dictionary = {}

func _init():
	if INSTANCE == null:
		INSTANCE = self
	else:
		return 
	
	var building_paths := Globals.get_all_file_paths(building_resources_path)
	
	for path in building_paths:
		var b = load(path) as BuildingDataResource
		b.init()
		_data[b.type] = b

func get_building_data(building_type: Type) -> BuildingDataResource:
	return _data[building_type]

func get_costs(building_type: Type) -> Dictionary:
	return get_building_data(building_type).costs
	
func get_cost(building_type: Type, resource_type: ResourceData.Resources) -> int:
	var costs = get_costs(building_type)
	return 0 if !costs.has(resource_type) else costs[resource_type]
