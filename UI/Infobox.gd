extends PanelContainer
class_name Infobox

@onready var label = $Label

func set_data(header: String, body: String):
	label.text = "%s\n%s" % [header, body]
