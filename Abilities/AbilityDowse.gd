extends PanelContainer


@export var info_popup: BuildingInfoPopup

var use_count = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Uses.text = str(use_count)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	use_count = get_parent().get_parent().get_parent().ability_dowse
	$Uses.text = str(use_count)
	if use_count <= 0:
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
			get_parent().get_parent().get_parent().ability("dowse")

func _on_mouse_entered():
	info_popup.visible = true
	info_popup.set_description("Dowse Tile", "Flag a random bomb")
	if use_count > 0 && get_parent().get_parent().get_parent().boards[len(get_parent().get_parent().get_parent().boards)-1].flags < 1:
		get_parent().get_parent().get_parent().help_text_is_overriden = true
		get_parent().get_parent().get_parent().help_text_bar.text = "Can't use dowse when there are no remaining flags to place."

func _on_mouse_exited():
	info_popup.visible = false
	if get_parent().get_parent().get_parent().help_text_is_overriden:
		get_parent().get_parent().get_parent().help_text_is_overriden = false
