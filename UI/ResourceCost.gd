extends HBoxContainer
class_name ResourceCostUI


@onready var icon = $Icon
@onready var label = $Label

func set_data(type: ResourceData.Resources, amt: int):
	icon.texture = load(ResourceData.data[type]["icon_path"])
	label.text = str(-amt)
