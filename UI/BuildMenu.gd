extends PanelContainer
class_name BuildMenu

signal on_building_selected(type: BuildingData.Type)

@onready var building_icon_container = $ScrollContainer/HBoxContainer
@onready var building_icon_prefab: PackedScene = preload("res://UI/BuildMenuBuildingIcon.tscn")

func set_stairs_placed(stairs_placed: bool):
	for child in building_icon_container.get_children():
		child.set_stairs_placed(stairs_placed)

func update_buildings(available_buildings):
	for child in building_icon_container.get_children():
		child.queue_free()
		
	# Grab that shit right from the bank baby
	for building_type in available_buildings:
		var new_icon = building_icon_prefab.instantiate()
		building_icon_container.add_child(new_icon)
		new_icon.type = building_type
		new_icon.clicked.connect(on_building_gui_input.bind(new_icon))
		
func on_building_gui_input( icon: BuildMenuBuildingIcon):
	on_building_selected.emit(icon.type)
