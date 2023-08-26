extends Control

signal ability_chosen(ability_name: String)

@onready var crane_button = $Panel/CraneButton
@onready var armor_button = $Panel/ArmorButton
@onready var scanner_button = $Panel/ScannerButton

@onready var confirm_button = $Panel/ConfirmButon
@onready var desc_label: Label = $Panel/SelectedDescriptionLabel

var currently_pressed: Button

func _process(delta):
	confirm_button.disabled = currently_pressed == null


func toggled(button, button_pressed):
	if currently_pressed != null && currently_pressed != button:
		currently_pressed.button_pressed = false
	if currently_pressed == button && !button_pressed:
		currently_pressed = null
		desc_label.hide()
	else:
		desc_label.show()
		currently_pressed = button

func _on_crane_button_toggled(button_pressed):
	toggled(crane_button, button_pressed)
	desc_label.text = "Crane: Safely Remove Tile"

func _on_armor_button_toggled(button_pressed):
	toggled(armor_button, button_pressed)
	desc_label.text = "Active Armor: Take No Damage When Uncovering Next Tile"

func _on_scanner_button_toggled(button_pressed):
	toggled(scanner_button, button_pressed)
	if button_pressed:
		desc_label.text = "Dowsing Rod: Reveal A Random Unflagged Bomb"

func _on_confirm_buton_pressed():
	if currently_pressed != null:
		var choice = "crane" if currently_pressed == crane_button else "armor" if currently_pressed == armor_button else "scanner"
		currently_pressed.button_pressed = false
		currently_pressed = null
		ability_chosen.emit(choice)

