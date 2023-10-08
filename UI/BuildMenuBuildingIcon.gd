extends TextureRect
class_name BuildMenuBuildingIcon

var type: BuildingData.Type : set = set_type

func set_type(val: BuildingData.Type):
	type = val
	texture = load(BuildingData.data[type]["icon_path"])
