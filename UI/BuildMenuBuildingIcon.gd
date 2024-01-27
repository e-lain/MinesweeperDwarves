extends VBoxContainer
class_name BuildMenuBuildingIcon

signal clicked

@onready var resource_cost_prefab = preload("res://UI/ResourceCost.tscn")

@onready var texture_rect = $HBoxContainer2/TextureRect
@onready var costs_container = $HBoxContainer


var type: BuildingData.Type : set = set_type

var current_stone
var current_pop
var current_steel

var stone_req
var pop_req
var steel_req

var stairs_placed: bool = false

var clickable = true

var scroll_container_swiping = false

func set_type(val: BuildingData.Type):
	type = val
	texture_rect.texture = load(BuildingData.data[type]["icon_path"])
	var costs = BuildingData.get_costs(val)
	for cost_type in costs.keys():
		var cost_value = costs[cost_type]
		var cost_ui_instance = resource_cost_prefab.instantiate()
		costs_container.add_child(cost_ui_instance)
		cost_ui_instance.set_data(cost_type, cost_value)

func _process(delta):
	var building_costs = BuildingData.get_costs(type)
	var cant_afford = false
	
	for cost_type in building_costs.keys():
		if Resources.amounts[cost_type] < building_costs[cost_type]:
			cant_afford = true
			break

	if !cant_afford && ((type != BuildingData.Type.STAIRCASE && (stairs_placed || type == BuildingData.Type.WONDER)) || (type == BuildingData.Type.STAIRCASE && !stairs_placed)):
		modulate = Color.WHITE
		clickable = true
	else:
		var new_color = Color.WHITE
		new_color.a = 0.5
		modulate = new_color
		clickable = false


func set_stairs_placed(val):
	stairs_placed = val

func handle_tap() -> void:
	if clickable:
		clicked.emit() 
