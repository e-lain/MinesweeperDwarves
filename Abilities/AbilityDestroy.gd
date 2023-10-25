extends PanelContainer

@export var main: Node2D
@export var info_popup: BuildingInfoPopup

var use_count = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Uses.text = str(use_count)
	info_popup.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	use_count = main.get_ability_charge_count(AbilityData.Type.DESTROY)
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
			print("destroy ability clicked")
			SoundManager.play_crane()
			main.ability(AbilityData.Type.DESTROY)

func _on_mouse_entered():
	info_popup.visible = true
	info_popup.set_description("Crane", "Safely Remove Tile")

func _on_mouse_exited():
	info_popup.visible = false
