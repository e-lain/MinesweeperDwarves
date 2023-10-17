extends HBoxContainer
class_name BuildingSelectionFill

signal on_move_pressed
signal on_destroy_pressed

@onready var label = $Label

func _on_move_pressed():
	on_move_pressed.emit()

func _on_destroy_pressed():
	on_destroy_pressed.emit()

func set_text(text: String):
	label.text = text
