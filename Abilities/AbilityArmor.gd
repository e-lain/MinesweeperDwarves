extends PanelContainer

@export var main: Node2D
@export var info_popup: BuildingInfoPopup

var entered: bool = false

var use_count = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Uses.text = str(use_count)
	info_popup.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	use_count = main.ability_armor
	$Uses.text = str(use_count)
	if use_count <= 0 || main.get_current_board().armor_active:
		var new_color = Color.WHITE
		new_color.a = 0.5
		modulate = new_color
	else:
		modulate = Color.WHITE

	if main.get_current_board().armor_active && entered:
		main.help_text_is_overriden = true
		main.help_text_bar.text = "Cannot activate again, active armor is already being used!"

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click") && use_count > 0:
			print("armor ability clicked")
			SoundManager.play_armor()
			main.ability("armor")

func _on_mouse_entered():
	entered = true
	info_popup.visible = true
	info_popup.set_description("Active Armor", "Take no damage when uncovering this next tile")
	if use_count > 0 && main.get_current_board().armor_active:
		main.help_text_is_overriden = true
		main.help_text_bar.text = "Cannot activate again, active armor is already being used!"

func _on_mouse_exited():
	entered = false
	info_popup.visible = false
	if main.get_current_board().armor_active:
		main.help_text_is_overriden = false
