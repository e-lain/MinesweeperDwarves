class_name Globals extends Node

const COLLECTION_EFFECT_LIFESPAN :float = 1.0

#TODO: Move to Mines?
const MINE_HIT_POPULATION_COST: int = 1  

const TILE_SIZE: int = 128
const TILE_SIZE_VECTOR: Vector2 = Vector2(TILE_SIZE, TILE_SIZE)

const ANIMATION_SPEED_MULTIPLIER: float = 2.0

## Util Function for converting from global (godot) position to cell (BoardTileController grid) position
static func global_to_cell(global_position: Vector2) -> Vector2i:
	return  Vector2i(int(global_position.x / Globals.TILE_SIZE), int(global_position.y / Globals.TILE_SIZE))

## Util function for converting 
static func cell_to_global(cell_position: Vector2i) -> Vector2:
	return cell_position * TILE_SIZE

static func snap_position(pos: Vector2) -> Vector2:
	@warning_ignore("integer_division")
	return Vector2(snapped(pos.x-TILE_SIZE/2, TILE_SIZE), snapped(pos.y-TILE_SIZE/2, TILE_SIZE))

static func instantiate_class_from_class_name(classname: String) -> Variant:
	var class_list := ProjectSettings.get_global_class_list()
	for class_data in class_list:
		if class_data["class"] == classname:
			return (load(class_data["path"]) as Script).new()
	
	push_error("No class with name %s found" % classname)
	return null

static func get_all_file_paths(path: String) -> Array[String]:  
	var file_paths: Array[String] = []  
	var dir = DirAccess.open(path)  
	dir.list_dir_begin()  
	var file_name = dir.get_next()  
	while file_name != "":  
		var file_path = path + "/" + file_name  
		if dir.current_is_dir():  
			file_paths.append(get_all_file_paths(file_path))  
		else:  
			file_paths.append(file_path)  
		file_name = dir.get_next()  
	return file_paths
