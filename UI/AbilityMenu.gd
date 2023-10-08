extends PanelContainer
class_name AbilityMenu

signal on_ability_selected(type: AbilityData.Type)

@onready var ability_icon_container = $ScrollContainer/HBoxContainer
@onready var ability_icon_prefab: PackedScene = preload("res://UI/AbilityMenuAbilityIcon.tscn")

func update_abilities(available_abilities: Array[AbilityData.Type]):
	for child in ability_icon_container.get_children():
		child.queue_free()
		

	for ability_type in available_abilities:
		var new_icon = ability_icon_prefab.instantiate()
		ability_icon_container.add_child(new_icon)
		new_icon.type = ability_type
		new_icon.gui_input.connect(on_ability_gui_input.bind(new_icon))
		
func on_ability_gui_input(event: InputEvent, icon: AbilityMenuAbilityIcon):
	if event is InputEventScreenTouch or event.is_action_released("left_click"):
		on_ability_selected.emit(icon.type)
