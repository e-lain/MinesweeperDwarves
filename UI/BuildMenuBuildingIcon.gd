extends TextureRect
class_name BuildMenuBuildingIcon

signal clicked

var type: BuildingData.Type : set = set_type

var current_stone
var current_pop
var current_steel

var stone_req
var pop_req
var steel_req

var stairs_placed: bool = false

var clickable = true

func set_type(val: BuildingData.Type):
	type = val
	texture = load(BuildingData.data[type]["icon_path"])


func _process(delta):
	current_stone = Resources.stone
	current_pop = Resources.population
	current_steel = Resources.steel
	
	var data = BuildingData.data[type]
	stone_req = data["stone_cost"]
	pop_req = data["population_cost"]
	steel_req = data["steel_cost"]
	if current_stone >= stone_req && current_pop > pop_req && current_steel >= steel_req && ((type != BuildingData.Type.STAIRCASE && (stairs_placed || type == BuildingData.Type.WONDER)) || (type == BuildingData.Type.STAIRCASE && !stairs_placed)):
		modulate = Color.WHITE
		clickable = true
	else:
		var new_color = Color.WHITE
		new_color.a = 0.5
		modulate = new_color
		clickable = false


func set_stairs_placed(val):
	stairs_placed = val

func _on_gui_input(event):
		if clickable and (event is InputEventScreenTouch or event.is_action_released("left_click")):
			clicked.emit()
