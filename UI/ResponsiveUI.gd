extends CanvasLayer

@onready var margin_container = $MarginContainer
@onready var top_margin = $MarginContainer/TopMargin
@onready var bottom_margin = $MarginContainer/BottomMargin

@onready var top_panel = $MarginContainer/TopPanel 
@onready var build_menu = $MarginContainer/BuildMenu 

@onready var infobox = $MarginContainer/TopMargin/Infobox
@onready var infobox_text = $MarginContainer/TopMargin/Infobox/Label
@onready var descend_button_container = $MarginContainer/TopMargin/DescendButton

@onready var floors_and_flags_portrait = $MarginContainer/TopPanel/FloorsAndFlags
@onready var floors_and_flags_landscape = $MarginContainer/FloorsAndFlagsLandscape

@onready var cancel_confirm = $MarginContainer/BottomMargin/CancelConfirm
@onready var cancel_placement = $MarginContainer/BottomMargin/CancelPlacement


# If we want to have margins around the UI, this would be where to assign them 
# as they will be overwritten by notch code
var top= 0
var left = 0 
var bottom = 0
var right = 0


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
	margin_container.add_theme_constant_override("margin_top",top)
	margin_container.add_theme_constant_override("margin_left",left)
	margin_container.add_theme_constant_override("margin_right",right)
	margin_container.add_theme_constant_override("margin_bottom",bottom)



# Called when the node enters the scene tree for the first time.
func _ready():
	on_dimensions_updated()
	

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


# TODO: Hook Up functionality
# TODO: Animate menus

func enter_build_mode():
	# TODO: Animate this!
	build_menu.visible = true
	descend_button_container.visible = true
	infobox.visible = true
	cancel_placement.visible = false
	cancel_confirm.visible = false

func enter_play_mode():
	# TODO: animate this!
	build_menu.visible = false
	descend_button_container.visible = false
	infobox.visible = false
	
func enter_place_mode():
	build_menu.visible = false
	cancel_placement.visible = true
	descend_button_container.visible = false

func on_building_placed():
	cancel_placement.visible = false
	cancel_confirm.visible = true
	
func on_building_placement_confirmed():
	cancel_confirm.visible = false
	descend_button_container.visible = true
	build_menu.visible = true
	infobox.visible = true
	


func _unhandled_input(event):
	if event.is_action_pressed("Test_1"):
		enter_build_mode()
	if event.is_action_pressed("Test_2"):
		enter_play_mode()
	if event.is_action_pressed("Test_3"):
		enter_place_mode()
	if event.is_action_pressed("Test_4"):
		on_building_placed()
	if event.is_action_pressed("Test_5"):
		on_building_placement_confirmed()
