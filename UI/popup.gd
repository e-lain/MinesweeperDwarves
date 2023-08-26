extends NinePatchRect
class_name BuildingInfoPopup

@onready var name_label: RichTextLabel = $NameLabel
@onready var description_label: RichTextLabel = $DescriptionLabel

@onready var population_box: HBoxContainer = $Costs/PopulationBox
@onready var stone_box: HBoxContainer = $Costs/StoneBox
@onready var steel_box: HBoxContainer = $Costs/SteelBox

@onready var population_icon: TextureRect = $Costs/PopulationBox/Population
@onready var population_label: Label = $Costs/PopulationBox/Label

@onready var stone_icon: TextureRect = $Costs/StoneBox/Stone
@onready var stone_label: Label = $Costs/StoneBox/Label

@onready var steel_icon: TextureRect = $Costs/SteelBox/Steel
@onready var steel_label: Label = $Costs/SteelBox/Label

func set_data(type: BuildingData.Type):
	var data = BuildingData.data[type]
	
	name_label.text = data["name"]
	description_label.text = data["description"]
	
	var population_cost = data["population_cost"]
	var stone_cost = data["stone_cost"] 
	var steel_cost = data["steel_cost"]
	
	if population_cost == 0:
		population_box.visible = false
	elif population_cost > 0:
		population_box.visible = true
		population_label.text = str(-population_cost)
	else:
		population_box.visible = true
		population_label.text = str(-population_cost)
	
	if stone_cost == 0:
		stone_box.visible = false
	elif stone_cost > 0:
		stone_box.visible = true
		stone_label.text = str(-stone_cost)
	else:
		stone_box.visible = true
		stone_label.text = str(-stone_cost)
		
	if steel_cost == 0:
		steel_box.visible = false
	elif steel_cost > 0:
		steel_box.visible = true
		steel_label.text = str(-steel_cost)
	else:
		steel_box.visible = true
		steel_label.text = str(-steel_cost)

func set_description(header: String, description: String):
	name_label.text = header
	description_label.text = description
	population_box.visible = false
	stone_box.visible = false
	steel_box.visible = false
