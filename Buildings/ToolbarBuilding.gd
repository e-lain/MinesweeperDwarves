extends PanelContainer
class_name ToolbarBuilding

signal build(type: BuildingData.Type)

@export var info_popup: BuildingInfoPopup
@export var type: BuildingData.Type
@export var resources_source: Node2D
@onready var texture_rect: TextureRect = $MarginContainer/TextureRect

var data

var clickable = true

func _ready():
	data = BuildingData.data[type]
	texture_rect.texture = load(data["icon_path"])

func _process(delta):
	var current_stone = resources_source.stone
	var current_pop = resources_source.population
	var stairs_placed = resources_source.stairs_placed()
	
	var stone_req = data["stone_cost"]
	var pop_req = data["population_cost"]
	if current_stone >= stone_req && current_pop >= pop_req && ((type != BuildingData.Type.STAIRCASE && stairs_placed) || (type == BuildingData.Type.STAIRCASE && !stairs_placed)):
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

func _on_mouse_exited():
	info_popup.visible = false


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click") && clickable:
			build.emit(type)


