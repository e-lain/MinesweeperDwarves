class_name BuildingData

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

static var _data := {}

static func _static_init():
	var building_paths := _get_all_file_paths(building_resources_path)
	
	for path in building_paths:
		var b = load(path) as BuildingDataResource
		_data[b.type] = b

static func _get_all_file_paths(path: String) -> Array[String]:  
	var file_paths: Array[String] = []  
	var dir = DirAccess.open(path)  
	dir.list_dir_begin()  
	var file_name = dir.get_next()  
	while file_name != "":  
		var file_path = path + "/" + file_name  
		if dir.current_is_dir():  
			file_paths.append(_get_all_file_paths(file_path))  
		else:  
			file_paths.append(file_path)  
		file_name = dir.get_next()  
	return file_paths

static func get_building_data(building_type: Type) -> BuildingDataResource:
	return _data[building_type]

static func get_costs(building_type: Type) -> Dictionary:
	return get_building_data(building_type).costs
	
static func get_cost(building_type: Type, resource_type: ResourceData.Resources) -> int:
	var costs = get_costs(building_type)
	return 0 if !costs.has(resource_type) else costs[resource_type]
