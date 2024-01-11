extends PanelContainer

@export var info_popup: BuildingInfoPopup
@export var main: Node2D

var use_count = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Uses.text = str(use_count)
	info_popup.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	use_count = main.get_ability_charge_count(AbilityData.Type.DESTROY)
	$Uses.text = str(use_count)
	if use_count <= 0 || main.get_current_board().flags < 1:
		var new_color = Color.WHITE
		new_color.a = 0.5
		modulate = new_color
	else:
		modulate = Color.WHITE

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click") && use_count > 0:
			print("dowse ability clicked")
			SoundManager.play_dowse()
			main.ability(AbilityData.Type.DOWSE)

func _on_mouse_entered():
	info_popup.visible = true
	info_popup.set_description("Dowse Tile", "Flag a random bomb")
	if use_count > 0 && main.get_current_board().flags < 1:
		main.help_text_is_overriden = true
		main.help_text_bar.text = "Can't use dowse when there are no remaining flags to place."

func _on_mouse_exited():
	info_popup.visible = false
	if main.help_text_is_overriden:
		main.help_text_is_overriden = false
