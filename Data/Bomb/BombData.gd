class_name BombData extends Resource

static var bomb_resources_path: String = "res://Data/Bomb/Resources/"

#region static data init
enum Type {
	Default,
	Lava
}

static var _data := {}

static func _static_init():
	var paths := Globals.get_all_file_paths(bomb_resources_path)
	
	for path in paths:
		var b = load(path)
		_data[b.type] = b
		
static func get_bomb_data(_type: Type) -> BombData:
	return _data[_type]
#endregion

#region Resource Type Variables
@export var type: Type
@export var name: String
@export var successful_flag_reward: Array[CostResource] = []
@export var texture: Texture2D
@export var model_script: Script
@export var view_scene: PackedScene

#endregion
