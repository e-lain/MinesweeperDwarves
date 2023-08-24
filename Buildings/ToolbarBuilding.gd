extends PanelContainer

signal build(type: BuildingData.Type)

@export var info_popup: BuildingInfoPopup
@export var type: BuildingData.Type
@onready var texture_rect: TextureRect = $MarginContainer/TextureRect

var data

func _ready():
	data = BuildingData.data[type]
	texture_rect.texture = load(data["icon_path"])

func _on_mouse_entered():
	info_popup.visible = true
	info_popup.set_data(type)


func _on_mouse_exited():
	info_popup.visible = false


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click"):
			build.emit(type)


