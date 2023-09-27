extends PanelContainer
class_name ToolbarBuilding

signal build(type: BuildingData.Type)

@export var info_popup: BuildingInfoPopup
@export var type: BuildingData.Type
@export var resources_source: Node2D #This is main
@onready var texture_rect: TextureRect = $MarginContainer/TextureRect

var current_stone
var current_pop
var current_steel

var stone_req
var pop_req
var steel_req

var stairs_placed: bool = false

var data

var clickable = true

func _ready():
	data = BuildingData.data[type]
	texture_rect.texture = load(data["icon_path"])
	info_popup.visible = false

func _process(delta):
	current_stone = resources_source.stone
	current_pop = resources_source.population
	current_steel = resources_source.steel
	stairs_placed = resources_source.stairs_placed()
	
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

func _on_mouse_entered():
	info_popup.visible = true
	info_popup.set_data(type)
	if !stairs_placed && type != BuildingData.Type.STAIRCASE:
		resources_source.help_text_is_overriden = true
		resources_source.help_text_bar.text = "Need to build staircase first!"
	elif  type == BuildingData.Type.STAIRCASE && stairs_placed && !resources_source.help_text_is_overriden:
		resources_source.help_text_is_overriden = true
		resources_source.help_text_bar.text = "Staircase is already built. Only one staircase can be built per floor"
	elif current_stone < stone_req || current_pop < pop_req || current_steel < steel_req:
		resources_source.help_text_is_overriden = true
		resources_source.help_text_bar.text = "Not enough resources to build"

func _on_mouse_exited():
	info_popup.visible = false
	if type == BuildingData.Type.STAIRCASE && stairs_placed:
		resources_source.help_text_is_overriden = false
	elif !stairs_placed && type != BuildingData.Type.STAIRCASE:
		resources_source.help_text_is_overriden = false
	elif current_stone < stone_req || current_pop < pop_req || current_steel < steel_req:
		resources_source.help_text_is_overriden = false

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click") && clickable:
			build.emit(type)


