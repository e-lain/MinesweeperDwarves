extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$Uses.text = str(0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Uses.text = str(get_parent().get_parent().get_parent().ability_destroy)


func _on_control_mouse_entered():
	var UINode = get_parent()
	var tooltip = UINode.get_node("Tooltip")
	tooltip.text = "Destroy tile ability"
	tooltip.show()

func _on_control_mouse_exited():
	var UINode = get_parent()
	UINode.get_node("Tooltip").hide()


func _on_control_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click"):
			print("destroy ability clicked")
			get_parent().get_parent().get_parent().ability("destroy")
