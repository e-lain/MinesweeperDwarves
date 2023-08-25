extends PanelContainer


@export var info_popup: BuildingInfoPopup

# Called when the node enters the scene tree for the first time.
func _ready():
	$Uses.text = str(0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Uses.text = str(get_parent().get_parent().get_parent().ability_destroy)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click"):
			print("destroy ability clicked")
			get_parent().get_parent().get_parent().ability("destroy")

func _on_mouse_entered():
	info_popup.visible = true
	info_popup.set_description("Engineer's Workshop", "Safely Remove Tile")

func _on_mouse_exited():
	info_popup.visible = false
