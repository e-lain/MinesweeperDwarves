extends Node

signal amounts_changed

func _ready():
	for type in ResourceData.Resources.values():
		amounts[type] = 0
	
	amounts[ResourceData.Resources.POPULATION] = 3 #300
	amounts[ResourceData.Resources.STONE] = 8 #800
	amounts[ResourceData.Resources.STEEL] = 3 #300

var amounts = {}

func get_amounts_copy():
	var ret = {}
	for type in ResourceData.Resources.values():
		ret[type] = amounts[type]
	return ret

func get_amount(type: ResourceData.Resources) -> int:
	return amounts[type]


func update_amount(type: ResourceData.Resources, delta: int) -> void:
	amounts[type] += delta
	amounts_changed.emit()


func add_amounts(costs: Array[CostResource]) -> void:
	for cost in costs:
		update_amount(cost.type, cost.amount)

func subtract_amounts(costs: Array[CostResource]) -> void:
	for cost in costs:
		update_amount(cost.type, -cost.amount)
