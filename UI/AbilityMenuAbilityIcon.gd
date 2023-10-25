extends TextureRect
class_name AbilityMenuAbilityIcon


signal clicked

var clickable = true

var type: AbilityData.Type : set = set_type

func set_type(val: AbilityData.Type):
	type = val
	texture = load(AbilityData.Data[type]["icon_path"])

func set_disabled(val: bool):
	clickable = !val
	modulate.a = 0.5 if val else 1.0
	
func _on_gui_input(event):
	if clickable and (event is InputEventScreenTouch or event.is_action_released("left_click")):
		clicked.emit()
