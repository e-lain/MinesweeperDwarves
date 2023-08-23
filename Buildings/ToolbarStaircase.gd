extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_control_mouse_entered():
	var UINode = get_parent()
	var tooltip = UINode.get_node("Tooltip")
	tooltip.text = "This is a staircase"
	tooltip.show()

func _on_control_mouse_exited():
	var UINode = get_parent()
	var tooltip = UINode.get_node("Tooltip")
	tooltip.hide()


func _on_control_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click"):
			print("staircase build button clicked")
			get_parent().get_parent().build("staircase")
