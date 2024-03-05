extends MarginContainer
class_name ResponsiveUI

signal enter_build_mode_pressed
signal descend_pressed
signal cancel_placement_pressed
signal confirm_placement_pressed
signal build_menu_item_pressed(type: BuildingData.Type)
signal ability_menu_item_pressed(type: AbilityData.Type)

signal move_selected_building_pressed
signal move_selected_building_cancelled
signal move_selected_building_confirmed
signal destroy_selected_building_pressed
signal board_unlock_pressed(board: Board)

signal tier_transition_midpoint 

@onready var top_margin = $TopMargin
@onready var bottom_margin = $BottomMargin

@onready var top_panel = $TopPanel 
@onready var build_menu: BuildMenu = $BuildMenu 
@onready var ability_menu: AbilityMenu = $AbilityMenu

@onready var infobox = $BottomMargin/Infobox

@onready var descend_button_container = $TopMargin/DescendButton
@onready var descend_button = $TopMargin/DescendButton/Button

@onready var floors_and_flags_portrait = $TopPanel/FloorsAndFlags
@onready var floors_and_flags_landscape = $FloorsAndFlagsLandscape

@onready var cancel_confirm = $BottomMargin/CancelConfirm
@onready var cancel_confirm_message = $BottomMargin/CancelConfirm/MarginContainer/VBoxContainer/Label
@onready var cancel_confirm_confirm_button = $BottomMargin/CancelConfirm/MarginContainer/VBoxContainer/HBoxContainer/Confirm
@onready var cancel_placement = $BottomMargin/CancelPlacement
@onready var cancel_placement_message = $BottomMargin/CancelPlacement/MarginContainer/HBoxContainer/Label

@onready var resource_bar: ResourceBar = $TopPanel/HBoxContainer/ResourceBar

# there's two for each because which one is chosen depends on screen layout. I hate it more than you
@onready var depth_label_portrait: Label = $TopPanel/FloorsAndFlags/FloorCount/Label
@onready var depth_label_landscape: Label = $FloorsAndFlagsLandscape/VBoxContainer/FloorCount/Label

@onready var flag_label_portrait: Label = $TopPanel/FloorsAndFlags/FlagCount/Label
@onready var flag_label_landscape: Label = $FloorsAndFlagsLandscape/VBoxContainer/FlagCount/Label

@onready var to_build_mode_button_container = $TopMargin/ToBuildModeButton
@onready var to_build_mode_button = $TopMargin/ToBuildModeButton/Button

@onready var alert_box: AlertBox = $AlertBox

@onready var transition = $Transition
@onready var transition_text = $Transition/TransitionText


var board_unlock_panel_prefab = preload("res://UI/BoardUnlockPanel.tscn")

# If we want to have margins around the UI, this would be where to assign them 
# as they will be overwritten by notch code
var top= 0
var left = 0 
var bottom = 0
var right = 0

enum State {
	PLAY,
	BUILD,
	AREA_CHOICE,
	PLACEMENT_NO_BUILDING,
	PLACEMENT_MOVE_BUILDING,
	SELECTED,
	MOVE_BUILDING,
	DESTROY_BUILDING,
	ALERT
}

var state: State
var prev_state: State
var selected_building: BuildingEntityView

var alert_proceed_callback

var board_unlock_panels = []

func _process(delta):
	if state == State.PLACEMENT_MOVE_BUILDING || state == State.MOVE_BUILDING:
		cancel_confirm_confirm_button.disabled = !selected_building.can_place()
	
	if board_unlock_panels != null:
		for panel in board_unlock_panels:
			var board = panel.board
			var t = board.get_global_transform_with_canvas()
			var board_pos = t.translated(board.get_size_global_position() / 2.0 * DragOrZoomEventManager.zoom_level).origin
			
			var size_factor = min(1.0, max((0.5 / DragOrZoomEventManager.get_zoom_level()), .1))
			panel.size = Vector2(240, 240) * size_factor
			panel.position = board_pos - (panel.size / 2)

func set_stairs_placed(placed: bool):
	build_menu.set_stairs_placed(placed)

func update_margins_for_notch():
	var safe_area = DisplayServer.get_display_safe_area()
	var window_size = DisplayServer.window_get_size()
	
	# CALQULATE EXTRA PADDING REQUIRED TO SKIP NOTCH
	if window_size.x >= safe_area.size.x and window_size.y >= safe_area.size.y:
		var x_factor = safe_area.size.x / float(window_size.x)
		var y_factor = safe_area.size.y / float(window_size.y)

		top = max(top, safe_area.position.y * y_factor)
		left = max(left, safe_area.position.x * x_factor)
		bottom = max(bottom, abs(safe_area.end.y - window_size.y) * y_factor)
		right = max(right, abs(safe_area.end.x - window_size.x) * x_factor)
		
	# OVERRIDE MARGIN CONTAINER (HOSTS THIS SCRIPT)
	add_theme_constant_override("margin_top",top)
	add_theme_constant_override("margin_left",left)
	add_theme_constant_override("margin_right",right)
	add_theme_constant_override("margin_bottom",bottom)


# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().get_root().size_changed.connect(on_dimensions_updated)
	on_dimensions_updated()
	state = State.PLAY

func update_buildings(buildings_list: Array[BuildingData.Type]) -> void:
	if !buildings_list:
		print("ERROR: BUILDINGS LIST PROVIDED IS INVALID")
		return
	build_menu.update_buildings(buildings_list)

func update_abilities(ability_charge_counts: Dictionary, ability_charge_maximums: Dictionary) -> void:
	var available_abilities = {}
	for ability_type in ability_charge_maximums.keys():
		if ability_charge_maximums[ability_type] > 0:
			available_abilities[ability_type] = true
	
	ability_menu.update_abilities(ability_charge_counts, available_abilities)

func update_resources(abilities_list: Array[ResourceData.Resources]) -> void:
	resource_bar.update_available_resources(abilities_list)

func on_dimensions_updated():
	update_margins_for_notch()
	var screen_size = get_viewport().get_visible_rect().size
	var current_size = top_panel.get_rect().size
	
	var min_height = screen_size.y * 0.05
	
	var top_panel_new_size = max(91, screen_size.y * 0.05)

	top_panel.custom_minimum_size.y = top_panel_new_size
	
	cancel_confirm.custom_minimum_size.y = min_height * 2
	
	if screen_size.x >= screen_size.y:
		# Landscape mode / Desktop mode

		top_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		top_margin.add_theme_constant_override("margin_top", 0)
		floors_and_flags_landscape.add_theme_constant_override("margin_top", top_panel_new_size)
		floors_and_flags_portrait.visible = false
		floors_and_flags_landscape.visible = true
	else:
		# Portrait / Mobile Mode

		top_panel.size_flags_horizontal = Control.SIZE_FILL
		top_margin.add_theme_constant_override("margin_top", top_panel_new_size)
		floors_and_flags_portrait.visible = true
		floors_and_flags_landscape.visible = false
	
	bottom_margin.add_theme_constant_override("margin_bottom", screen_size.y * 0.01)

func enter_build_mode():
	state = State.BUILD
	# TODO: Animate this!
	ability_menu.visible = false
	build_menu.visible = true
	to_build_mode_button_container.visible = false
	descend_button_container.visible = true
	#infobox.visible = true
	cancel_placement.visible = false
	cancel_confirm.visible = false

func enter_play_mode():
	clear_board_unlock_panels()
	state = State.PLAY
	ability_menu.show_if_abilities_available()
	# TODO: animate this!
	build_menu.visible = false
	to_build_mode_button_container.visible = true
	descend_button_container.visible = false
	infobox.visible = false
	alert_box.visible = false
	
func enter_place_mode(type: BuildingData.Type):
	var data = BuildingData.get_building_data(type)
	var name = data.name
	state = State.PLACEMENT_NO_BUILDING
	build_menu.visible = false
	cancel_placement.visible = true
	cancel_placement_message.text = "Placing %s" % name
	to_build_mode_button_container.visible = false
	descend_button_container.visible = false

func enter_area_choice_mode():
	state = State.AREA_CHOICE
	build_menu.visible = false
	descend_button_container.visible = false
	infobox.visible = false
	alert_box.visible = false

func on_building_placement_instantiated(building: BuildingEntityView):
	if state == State.PLACEMENT_NO_BUILDING:
		selected_building = building

func on_building_placed():
	state = State.PLACEMENT_MOVE_BUILDING
	build_menu.visible = false
	cancel_placement.visible = false
	cancel_confirm.visible = true
	cancel_confirm_message.text = "Place Building Here?"

func set_depth(depth: int):
	depth_label_portrait.text = str(depth)
	depth_label_landscape.text = str(depth)

func set_flag_count(flag_count: int):
	flag_label_portrait.text = str(flag_count)
	flag_label_landscape.text = str(flag_count)

func set_resource_count(type: ResourceData.Resources, val: int):
	resource_bar.set_resource_count(type, val)

func set_enter_build_mode_disabled(val: bool):
	to_build_mode_button.disabled = val

func set_descend_disabled(val: bool):
	descend_button.disabled = val

func on_building_selected(building: BuildingEntityView):
	state = State.SELECTED 
	selected_building = building
	
	var data = building.get_building_data()
	infobox.set_building_selection(data.type, data.name, data.description)
	cancel_confirm.visible = false
	cancel_placement.visible = false
	infobox.visible = true
	build_menu.visible = false
	descend_button_container.visible = false

func on_building_deselected():
	state = State.BUILD
	cancel_confirm.visible = false
	infobox.visible = false
	build_menu.visible = true
	selected_building = null
	descend_button_container.visible = true
	alert_box.visible = false

func _on_descend_button_pressed():
	descend_pressed.emit()
	
func show_floor_descend_warning(proceed_callback: Callable):
	prev_state = state
	state = State.ALERT
	alert_proceed_callback = proceed_callback
	alert_box.show_content("[center]Watch Out![/center]", "[center]There are buildings which will not generate resources. Proceed?[/center]", Vector2(480, 360), AlertBox.ButtonStyle.Proceed, _on_alert_box_proceed_pressed, _on_alert_box_cancel_pressed)
	cancel_confirm.visible = false
	infobox.visible = false
	build_menu.visible = false
	selected_building = null
	descend_button_container.visible = false

func show_mine_hit_popup(restart_callback: Callable) -> void:
	prev_state = state
	state = State.ALERT
	alert_proceed_callback = restart_callback
	alert_box.show_content("[center]Mine Hit![/center]", "[center]You hit a mine. One Population has been lost.[/center]", Vector2(480, 360), AlertBox.ButtonStyle.Restart, _on_alert_box_proceed_pressed)
	cancel_confirm.visible = false
	infobox.visible = false
	build_menu.visible = false
	selected_building = null
	descend_button_container.visible = false

func _on_alert_box_cancel_pressed():
	alert_proceed_callback = null
	on_building_deselected()

func _on_alert_box_proceed_pressed():
	if prev_state == State.PLAY:
		enter_play_mode()
	else:
		on_building_deselected()
	if alert_proceed_callback != null and alert_proceed_callback is Callable:
		alert_proceed_callback.call()
	alert_proceed_callback = null

func _on_to_build_mode_button_pressed():
	enter_build_mode_pressed.emit()

func _on_build_menu_on_building_selected(type: BuildingData.Type):
	build_menu_item_pressed.emit(type)
	
func _on_building_placement_cancel_pressed():
	if state == State.PLACEMENT_MOVE_BUILDING || state == State.PLACEMENT_NO_BUILDING:
		cancel_placement_pressed.emit()
	elif state == State.DESTROY_BUILDING:
		on_building_selected(selected_building)
	elif state == State.MOVE_BUILDING:
		move_selected_building_cancelled.emit()

func _on_building_placement_confirm_pressed():
	if state == State.PLACEMENT_MOVE_BUILDING || state == State.PLACEMENT_NO_BUILDING:
		confirm_placement_pressed.emit()
	elif state == State.DESTROY_BUILDING:
		destroy_selected_building_pressed.emit()
	elif state == State.MOVE_BUILDING:
		move_selected_building_confirmed.emit()

func _on_ability_menu_ability_selected(type: AbilityData.Type):
	ability_menu_item_pressed.emit(type)

func _on_move_selected_building_pressed():
	state = State.MOVE_BUILDING
	cancel_confirm.visible = true
	cancel_confirm_message.text = "Move Building Here?"
	infobox.visible = false
	move_selected_building_pressed.emit()

func _on_destroy_selected_building_pressed():
	state = State.DESTROY_BUILDING
	infobox.visible = false
	cancel_confirm.visible = true
	cancel_confirm_message.text = "Destroy Building?"

func show_transition(to_tier: int) -> void:
	transition.modulate = Color(1, 1, 1, 0)
	transition.visible = true
	transition_text.text = "[center][wave amp=50.0 freq=10.0]%s[/wave][/center]" % BiomeData.data[to_tier]["name"]
	var tween = create_tween().bind_node(self)
	tween.tween_property(transition, "modulate", Color(1, 1, 1, 1), 2.0)
	tween.tween_callback(hide_transition)

func hide_transition():
	tier_transition_midpoint.emit()
	var tween = create_tween().bind_node(self)
	tween.tween_property(transition, "modulate", Color(1, 1, 1, 0), 2.0)
	tween.tween_callback(on_hide_transition_complete)

func on_hide_transition_complete():
	transition.visible = false

func hide_enter_build_mode():
	to_build_mode_button_container.visible = false

func clear_board_unlock_panels():
	if board_unlock_panels == null:
		return
		
	for panel in board_unlock_panels:
		panel.queue_free()
	board_unlock_panels = []

func spawn_board_unlock_panel(board: Board):
	var instance = board_unlock_panel_prefab.instantiate()
	add_child(instance)
	instance.initialize(board)
	instance.unlock_pressed.connect(on_unlock_board_button_pressed.bind(board))
	board_unlock_panels.append(instance)

func on_unlock_board_button_pressed(board: Board):
	board_unlock_pressed.emit(board)
