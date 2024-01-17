extends Control
class_name BuildMenu

signal on_building_selected(type: BuildingData.Type)

@onready var scroll_container = $ScrollContainer
@onready var building_icon_container = $ScrollContainer/HBoxContainer
@onready var building_icon_prefab: PackedScene = preload("res://UI/BuildMenuBuildingIcon.tscn")


func _ready():
	get_tree().get_root().size_changed.connect(on_window_resized)
	on_window_resized()

func on_window_resized():
	var viewport_size = get_viewport().get_visible_rect().size
	var size = DisplayServer.window_get_size()
	var vertical = size.y > size.x
	var x_width = viewport_size.x if vertical else viewport_size.x * .8
	var new_min_size = Vector2(x_width, viewport_size.y * .1875)
	custom_minimum_size = new_min_size
	scroll_container.custom_minimum_size = new_min_size

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
