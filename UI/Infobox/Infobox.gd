extends PanelContainer
class_name Infobox

signal on_building_move_pressed
signal on_building_destroy_pressed


var label_fill_prefab = preload("res://UI/Infobox/LabelFill.tscn")
var building_selection_fill_prefab = preload("res://UI/Infobox/BuildingSelectionFill.tscn")

var content

func build_text(header: String, body: String) -> String:
	return  "%s\n%s" % [header, body]

func set_label(header: String, body: String):
	if content != null:
		content.queue_free()
	content = label_fill_prefab.instantiate()
	add_child(content)
	content.text = build_text(header, body)
	
func set_building_selection(type: BuildingData.Type, header: String, body: String):
	if content != null:
		content.queue_free()
	content = building_selection_fill_prefab.instantiate()
	add_child(content)
	content.set_type(type)
	content.set_text(build_text(header, body))
	content.on_move_pressed.connect(func(): on_building_move_pressed.emit())
	content.on_destroy_pressed.connect(func(): on_building_destroy_pressed.emit())
