extends HBoxContainer
class_name BuildingSelectionFill

signal on_move_pressed
signal on_destroy_pressed

@onready var label = $Label
@onready var destory_button = $Destroy


func _on_move_pressed():
	on_move_pressed.emit()

func _on_destroy_pressed():
	on_destroy_pressed.emit()

func set_text(text: String):
	label.text = text

func set_type(type: BuildingData.Type):
	destory_button.disabled = type == BuildingData.Type.STAIRCASE
