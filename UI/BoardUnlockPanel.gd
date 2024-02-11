extends PanelContainer

signal unlock_pressed

var board: Board

var resource_cost_prefab = preload("res://UI/ResourceCost.tscn")


@onready var size_label = $MarginContainer/VBoxContainer/Label
@onready var resource_bar = $MarginContainer/VBoxContainer/ResourceBar
@onready var button = $MarginContainer/VBoxContainer/Button

func _ready():
	Resources.amounts_changed.connect(on_resources_changed)

func initialize(b: Board):
	board = b
	size_label.text = "%d x %d" % [b.rows, b.columns]
	for type in b.unlock_costs.keys():
		var instance = resource_cost_prefab.instantiate()
		resource_bar.add_child(instance)
		instance.set_data(type, b.unlock_costs[type])

func on_resources_changed():
	for type in board.unlock_costs.keys():
		if Resources.get_amount(type) < board.unlock_costs[type]:
			button.disabled = true
			return
	
	button.disabled = false

func _on_button_pressed():
	unlock_pressed.emit()

