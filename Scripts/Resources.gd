extends Node

func _ready():
	for type in ResourceData.Resources.values():
		amounts[type] = 0
	
	amounts[ResourceData.Resources.POPULATION] = 300 #3
	amounts[ResourceData.Resources.STONE] = 800 #8
	amounts[ResourceData.Resources.STEEL] = 300 #3

var amounts = {}
