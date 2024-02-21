extends Node

signal amounts_changed

func _ready():
	for type in ResourceData.Resources.values():
		amounts[type] = 0
	
	amounts[ResourceData.Resources.POPULATION] = 300 #3
	amounts[ResourceData.Resources.STONE] = 800 #8
	amounts[ResourceData.Resources.STEEL] = 300 #3

var amounts = {}

func get_amounts_copy():
	var ret = {}
	for type in ResourceData.Resources.values():
		ret[type] = amounts[type]
	return ret

func get_amount(type: ResourceData.Resources):
	return amounts[type]


func update_amount(type: ResourceData.Resources, delta: int):
	amounts[type] += delta
	amounts_changed.emit()
