extends HBoxContainer

@onready var texture_rect = $TextureRect
@onready var label = $Label

var type: ResourceData.Resources

func set_data(type: ResourceData.Resources, amount: int):
	self.type = type
	texture_rect.texture = load(ResourceData.data[type]["icon_path"])
	label.text = str(amount)


func update_amount(amt: int):
	label.text = str(amt)
