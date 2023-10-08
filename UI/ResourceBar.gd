extends HBoxContainer
class_name ResourceBar

@onready var stone_label = $Stone/Label
@onready var population_label = $Population/Label
@onready var steel_label = $Steel/Label
@onready var lava_label = $Lava/Label


func set_resource_count(type: ResourceData.Resources, val: int):
	var label
	match type:
		ResourceData.Resources.STONE:
			label = stone_label
		ResourceData.Resources.POPULATION:
			label = population_label
		ResourceData.Resources.STEEL:
			label = steel_label
		ResourceData.Resources.SLEDGEHAMMER, ResourceData.Resources.LAVA:
			label = lava_label
	label.text = "x %d" % val
