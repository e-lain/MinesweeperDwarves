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

@onready var top_margin = $TopMargin
@onready var bottom_margin = $BottomMargin

@onready var top_panel = $TopPanel 
@onready var build_menu: BuildMenu = $BuildMenu 
@onready var ability_menu: AbilityMenu = $AbilityMenu

@onready var infobox = $TopMargin/Infobox

@onready var descend_button_container = $TopMargin/DescendButton
@onready var descend_button = $TopMargin/DescendButton/Button

@onready var floors_and_flags_portrait = $TopPanel/FloorsAndFlags
@onready var floors_and_flags_landscape = $FloorsAndFlagsLandscape

@onready var cancel_confirm = $BottomMargin/CancelConfirm
@onready var cancel_confirm_message = $BottomMargin/CancelConfirm/MarginContainer/VBoxContainer/Label
@onready var cancel_placement = $BottomMargin/CancelPlacement
@onready var cancel_placement_message = $BottomMargin/CancelPlacement/MarginContainer/HBoxContainer/Label

@onready var resource_bar: ResourceBar = $TopPanel/ResourceBar

# there's two for each because which one is chosen depends on screen layout. I hate it more than you
@onready var depth_label_portrait: Label = $TopPanel/FloorsAndFlags/FloorCount/Label
@onready var depth_label_landscape: Label = $FloorsAndFlagsLandscape/VBoxContainer/FloorCount/Label

@onready var flag_label_portrait: Label = $TopPanel/FloorsAndFlags/FlagCount/Label
@onready var flag_label_landscape: Label = $FloorsAndFlagsLandscape/VBoxContainer/FlagCount/Label

@onready var to_build_mode_button_container = $TopMargin/ToBuildModeButton
@onready var to_build_mode_button = $TopMargin/ToBuildModeButton/Button


# If we want to have margins around the UI, this would be where to assign them 
# as they will be overwritten by notch code
var top= 0
var left = 0 
var bottom = 0
var right = 0

enum State {
	PLAY,
	BUILD,
	PLACEMENT_NO_BUILDING,
	PLACEMENT_MOVE_BUILDING,
	SELECTED,
	MOVE_BUILDING,
	DESTROY_BUILDING
}

var state
var selected_building

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
	ability_menu.update_abilities([AbilityData.Type.ARMOR, AbilityData.Type.DESTROY, AbilityData.Type.DOWSE])
	on_dimensions_updated()
	state = State.PLAY

func update_buildings(buildings_list):
	if !buildings_list:
		print("ERROR: BUILDINGS LIST PROVIDED IS INVALID")
		return
	build_menu.update_buildings(buildings_list)

func on_dimensions_updated():
	update_margins_for_notch()
	var screen_size = get_viewport().get_visible_rect().size
	var current_size = top_panel.get_rect().size
	
	var min_height = screen_size.y * 0.05
	
	var top_panel_new_size = max(min_height, current_size.y)

	top_panel.custom_minimum_size.y = top_panel_new_size
	build_menu.custom_minimum_size.y = min_height * 2.5
	
	cancel_confirm.custom_minimum_size.y = min_height * 2
	
	if screen_size.x >= screen_size.y:
		# Landscape mode / Desktop mode

		top_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		build_menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		build_menu.custom_minimum_size.x = screen_size.x * 0.66
		top_margin.add_theme_constant_override("margin_top", 0)
		floors_and_flags_landscape.add_theme_constant_override("margin_top", top_panel_new_size)
		floors_and_flags_portrait.visible = false
		floors_and_flags_landscape.visible = true
	else:
		# Portrait / Mobile Mode

		top_panel.size_flags_horizontal = Control.SIZE_FILL
		build_menu.size_flags_horizontal = Control.SIZE_FILL
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
	state = State.PLAY
	ability_menu.visible = true
	# TODO: animate this!
	build_menu.visible = false
	to_build_mode_button_container.visible = true
	descend_button_container.visible = false
	infobox.visible = false
	
func enter_place_mode(type: BuildingData.Type):
	var data = BuildingData.data[type]
	var name = data["name"]
	state = State.PLACEMENT_NO_BUILDING
	build_menu.visible = false
	cancel_placement.visible = true
	cancel_placement_message.text = "Placing %s" % name
	to_build_mode_button_container.visible = false
	descend_button_container.visible = false
	

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

func on_building_selected(building: BaseBuilding):
	state = State.SELECTED
	selected_building = building
	var data = BuildingData.data[building.type] 
	infobox.set_building_selection(data["name"], data["description"])
	cancel_confirm.visible = false
	cancel_placement.visible = false
	infobox.visible = true
	build_menu.visible = false

func on_building_deselected():
	state = State.BUILD
	cancel_confirm.visible = false
	infobox.visible = false
	build_menu.visible = true
	selected_building = null

func _on_descend_button_pressed():
	descend_pressed.emit()

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
