extends Node2D

@onready var mine_hit_popup = $CanvasLayer/MineHitPopup
@onready var greyout = $CanvasLayer/ColorRect

@onready var responsive_ui = $ResponsiveUICanvas/ResponsiveUI

@onready var destroy_popup = $CanvasLayer/AbilityMenu/DestroyPopup
@onready var armor_popup = $CanvasLayer/AbilityMenu/ArmorPopup
@onready var dowse_popup = $CanvasLayer/AbilityMenu/DowsePopup

@onready var help_overlay_play = $CanvasLayer/HelpOverlayPlay
@onready var help_overlay_build = $CanvasLayer/HelpOverlayBuild
@onready var help_text_bar = $CanvasLayer/UI/ContextLabel
var help_text_is_overriden: bool = false

@onready var game_over = $CanvasLayer/GameOver
@onready var you_win = $CanvasLayer/YouWin

@onready var camera = $Camera2D

var Board = preload("res://board.tscn")

var build_mode: bool = false

var tier = 1
var depth_by_tier = {}
var available_buildings = []
 
var ability_charge_maximums = { AbilityData.Type.ARMOR: 0, AbilityData.Type.DESTROY: 0, AbilityData.Type.DOWSE: 0 }
var ability_charge_counts = {}

var total_workshop_count = 0

var overlay_toggled: bool = false

var current_board

var icons = {}

var state = State.Play

enum State {
	Play,
	Build,
	Placing
}


func generate_board(difficulty: int):
	help_text_is_overriden = false
	destroy_popup.visible = false
	armor_popup.visible = false
	dowse_popup.visible = false
	
	# Reset all ability counts
	ability_charge_counts = ability_charge_maximums.duplicate()
	responsive_ui.update_abilities(ability_charge_counts, ability_charge_maximums)
	var b = Board.instantiate()
	if current_board:
		current_board.queue_free()
	current_board = b
	
	add_child(b)
	
	if tier == 1:
		b.init_board(6,6,4,tier)
	elif tier == 2:
		if difficulty == 0:
			b.init_board(6,6,4,tier)
		elif difficulty == 1:
			b.init_board(7,7,5,tier)
		elif difficulty == 2:
			b.init_board(8,8,7,tier)
		elif difficulty == 3:
			b.init_board(9,9,9,tier)
		else:
			b.init_board(10,10,10,tier)
	else:
		b.init_board(6,6,4,tier)
	
	var board_size_global = Vector2(b.columns * b.TILE_SIZE, b.rows * b.TILE_SIZE)
	
	b.position = -(board_size_global / 2)
	b.create_grid_lines()
	b.mine_animation_complete.connect(on_mine_animation_complete)
	b.wonder_placed.connect(on_wonder_placed)
	b.workshop_placed.connect(on_workshop_placed)
	b.workshop_destroyed.connect(on_workshop_destroyed)
	b.on_building_collection_complete.connect(on_building_collection_complete)
	b.on_minesweeper_collection_complete.connect(on_minesweeper_collection_complete)
	
	b.placing_building_instantiated.connect(on_placing_building_instantiated)
	b.building_placed.connect(on_building_placed)
	
	b.building_selected.connect(on_building_selected)
	b.building_deselected.connect(on_building_deselected)
	
	b.ability_complete.connect(on_ability_completed)
	
	move_child(camera, -1)
	camera.reset(Vector2.ZERO, board_size_global)

# Called when the node enters the scene tree for the first time.
func _ready():
	depth_by_tier[tier] = 0
	for key in BuildingData.data.keys():
		icons[key] = load(BuildingData.data[key]["icon_path"])
	
	# place board in center with correct offset accounting for tile size and board size
	generate_board(0)
	test_new_tier()
	responsive_ui.update_buildings(available_buildings)
	responsive_ui.update_abilities(ability_charge_counts, ability_charge_maximums)
	responsive_ui.enter_play_mode()

func test_new_tier():
	#TESTING
	# Keep this commented except for when jumping straight to a higher tier for testing
	# TODO: Re-Comment this when done testing

	tier = 1  #2
	available_buildings.append_array(BiomeData.get_buildings(tier))

func get_depth() -> int:
	return depth_by_tier[tier]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	responsive_ui.set_resource_count(ResourceData.Resources.POPULATION, Resources.population)
	responsive_ui.set_resource_count(ResourceData.Resources.STONE, Resources.stone)
	responsive_ui.set_resource_count(ResourceData.Resources.STEEL, Resources.steel)
	responsive_ui.set_resource_count(ResourceData.Resources.SLEDGEHAMMER, Resources.sledgehammer)
	responsive_ui.set_depth(get_depth() + 1)
	
	if get_current_board():
		responsive_ui.set_flag_count(get_current_board().flags)
		responsive_ui.set_enter_build_mode_disabled(!can_enter_build_mode())
		
		responsive_ui.set_descend_disabled(!stairs_placed())
		responsive_ui.set_stairs_placed(stairs_placed())
	
	if !help_text_is_overriden:
		help_text_bar.text = "Press \'H\' for help overlay"


func can_enter_build_mode() -> bool:
	return get_current_board().tiles_uncovered != 0

func ability(ability_name: AbilityData.Type):
	if get_current_board().mine_exploded:
		return
		
	if ability_charge_counts[ability_name] <= 0:
		print("Cant use %s, out of uses" % str(ability_name))
		return
	
	
	print("func ability, ability_name: ", ability_name)

	if ability_name == AbilityData.Type.ARMOR:
		if get_current_board().armor_active:
			# Prevent player from stacking armor uses on a single turn
			return
		else:
			ability_charge_counts[ability_name] -= 1
	elif ability_name == AbilityData.Type.DOWSE:
		if get_current_board().flags < 1:
			print("can't use dowse, out of flags")
			return
		
	get_current_board().queue_ability(ability_name)

func start_placement(type: BuildingData.Type):
	state = State.Placing
	print("func start_placement, building_name: ", type)
	
	responsive_ui.enter_place_mode(type)
	get_current_board().queue_building(type)
	
	DragOrZoomEventManager.drag_blocked = true

func on_building_placed():
	responsive_ui.on_building_placed()
	DragOrZoomEventManager.drag_blocked = false

func on_building_selected(building: BaseBuilding):
	responsive_ui.on_building_selected(building)

func on_building_deselected():
	responsive_ui.on_building_deselected()


func next_level():
	responsive_ui.set_tier(tier)
	get_current_board().queue_free()
	
	print("MAIN SCENE RECEIVED NEXT LEVEL CALL")
	depth_by_tier[tier] += 1
	
	state = State.Play
	
	generate_board(get_depth())
	responsive_ui.update_buildings(available_buildings)
	responsive_ui.enter_play_mode()

func _on_responsive_ui_enter_build_mode_pressed():
	if state != State.Build:
		get_current_board().enter_build_mode()
	else:
		push_error("ALREADY IN BUILD MODE but end level button pressed")


func on_mine_animation_complete():
	get_tree().paused = true
	SoundManager.play_negative()
	if Resources.population > 0:
		mine_hit_popup.visible = true
		greyout.visible = true
	elif Resources.population == 0:
		game_over.show()
		greyout.show()

func _on_mine_hit_restart_level_pressed():
	mine_hit_popup.visible = false
	greyout.visible = false
	get_current_board().queue_free()
	generate_board(get_depth())
	get_tree().paused = false


func stairs_placed():
	return get_current_board().stairs_placed

func get_current_board():
	return current_board

func _on_responsive_ui_descend_pressed():
	get_current_board().collect_resources()

func on_resource_collection_complete():
	next_level()

func _on_win_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene() # TODO: GO TO TITLE SCREEN

func _on_loss_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()  # TODO: GO TO TITLE SCREEN

func on_wonder_placed():
	SoundManager.play_positive()
	you_win.show()
	greyout.show()
	get_tree().paused = true

func on_workshop_placed():
	total_workshop_count += 1
	# TODO: Some kind of user feedback notifying tier has been progressed
	if tier < 2:
		tier += 1
		depth_by_tier[tier] = -1
		
	ability_charge_maximums[AbilityData.Type.DESTROY] += 1


func on_workshop_destroyed():
	total_workshop_count -= 1
	if total_workshop_count == 0:
		tier -= 1
	
	ability_charge_maximums[AbilityData.Type.DESTROY] -= 1


func on_ability_completed():
	responsive_ui.update_abilities(ability_charge_counts, ability_charge_maximums)

func get_ability_charge_count(type: AbilityData.Type):
	return ability_charge_counts[type]

func use_ability_charge(type: AbilityData.Type):
	ability_charge_counts[type] -= 1

func _input(event):
	if event is InputEventKey and Input.is_key_label_pressed(KEY_H):	
		overlay_toggled = !overlay_toggled
			
		if get_current_board().build_mode == false:
			help_overlay_play.visible = !help_overlay_play.visible
		elif get_current_board().build_mode == true:
			help_overlay_build.visible = !help_overlay_build.visible
			
		if overlay_toggled:
			var new_color = Color.WHITE
			new_color.a = 0.1
			modulate = new_color
		else:
			modulate = Color.WHITE

func _on_end_level_btn_mouse_entered():
	if !can_enter_build_mode() && !help_text_is_overriden:
		SoundManager.play_negative()
		help_text_is_overriden = true
		help_text_bar.text = "Can't enter build mode until at least one tile is cleared!"


func _on_end_level_btn_mouse_exited():
	help_text_is_overriden = false

func on_building_collection_complete():
	on_resource_collection_complete()

func on_minesweeper_collection_complete():
	state = State.Build
	responsive_ui.enter_build_mode()

func _on_responsive_ui_build_menu_item_pressed(type):
	start_placement(type)


func _on_responsive_ui_cancel_placement_pressed():
	get_current_board().on_cancel_building_placement()
	responsive_ui.enter_build_mode()


func _on_responsive_ui_confirm_placement_pressed():
	get_current_board().on_confirm_building_placement()
	responsive_ui.enter_build_mode()


func _on_responsive_ui_ability_menu_item_pressed(type: AbilityData.Type):
	ability(type)


func _on_camera_2d_drag_complete():
	pass # Replace with function body.


func _on_camera_2d_tap_complete(event):
	get_current_board().deselect_building(event)

func _on_responsive_ui_destroy_selected_building_pressed():
	get_current_board().destroy_selected_building()

func _on_responsive_ui_move_selected_building_pressed():
	get_current_board().move_selected_building()


func _on_responsive_ui_move_selected_building_cancelled():
	get_current_board().cancel_selected_building_move()


func _on_responsive_ui_move_selected_building_confirmed():
	get_current_board().confirm_selected_building_move()

func on_placing_building_instantiated(building: BaseBuilding):
	responsive_ui.on_building_placement_instantiated(building)
