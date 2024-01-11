extends PanelContainer
class_name AbilityMenu

signal on_ability_selected(type: AbilityData.Type)

@onready var ability_icon_container = $ScrollContainer/HBoxContainer
@onready var ability_icon_prefab: PackedScene = preload("res://UI/AbilityMenuAbilityIcon.tscn")

var should_show = false

func update_abilities(ability_counts: Dictionary, available_abilities: Dictionary):
	for child in ability_icon_container.get_children():
		child.queue_free()
		

	for ability_type in ability_counts.keys():
		if ability_type not in available_abilities:
			continue
		var new_icon = ability_icon_prefab.instantiate()
		ability_icon_container.add_child(new_icon)
		new_icon.type = ability_type
		new_icon.clicked.connect(on_ability_gui_input.bind(new_icon))
		new_icon.set_disabled(ability_counts[ability_type] <= 0)
	
	should_show = !available_abilities.is_empty()
	
func on_ability_gui_input(icon: AbilityMenuAbilityIcon):
	on_ability_selected.emit(icon.type)
	
func show_if_abilities_available():
	visible = should_show
