extends TextureRect
class_name AbilityMenuAbilityIcon

var type: AbilityData.Type : set = set_type

func set_type(val: AbilityData.Type):
	type = val
	texture = load(AbilityData.Data[type]["icon_path"])
