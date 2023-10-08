extends Node2D

@onready var mine_hit_popup = $CanvasLayer/MineHitPopup
@onready var greyout = $CanvasLayer/ColorRect

@onready var responsive_ui: ResponsiveUI = $ResponsiveUICanvas/ResponsiveUI

@onready var destroy_popup = $CanvasLayer/AbilityMenu/DestroyPopup
@onready var armor_popup = $CanvasLayer/AbilityMenu/ArmorPopup
@onready var dowse_popup = $CanvasLayer/AbilityMenu/DowsePopup

@onready var help_overlay_play = $CanvasLayer/HelpOverlayPlay
@onready var help_overlay_build = $CanvasLayer/HelpOverlayBuild
@onready var help_text_bar = $CanvasLayer/UI/ContextLabel
var help_text_is_overriden: bool = false

@onready var game_over = $CanvasLayer/GameOver
@onready var you_win = $CanvasLayer/YouWin

@onready var choose_active = $CanvasLayer/ChooseActive

var Board = preload("res://board.tscn")

var build_mode: bool = false

var tier = 0
var depth = 0
var population = 3
var stone = 8
var steel = 3
 
var ability_destroy_max = 0
var ability_destroy = 0

var ability_armor_max = 0
var ability_armor = 0

var ability_dowse_max = 0
var ability_dowse = 0

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
	ability_destroy = ability_destroy_max
	ability_armor = ability_armor_max
	ability_dowse = ability_dowse_max 
	var b = Board.instantiate()
	if current_board:
		current_board.queue_free()
	current_board = b
	
	add_child(b)
	
	if difficulty == 0:
		b.init_board(6,6,4,0)
	elif difficulty == 1:
		b.init_board(7,7,5,0)
	elif difficulty == 2:
		b.init_board(8,8,7,0)
	elif difficulty == 3:
		b.init_board(9,9,9,0)
	else:
		b.init_board(10,10,10,0)
		
	var center = get_viewport_rect().size/2
	var offset = Vector2(center.x-(b.rows * b.TILE_SIZE/2), center.y-(b.columns * b.TILE_SIZE/2))
	b.position = offset
	b.create_grid_lines()
	b.mine_animation_complete.connect(on_mine_animation_complete)
	b.wonder_placed.connect(on_wonder_placed)
	b.workshop_placed.connect(on_workshop_placed)
	b.on_building_collection_complete.connect(on_building_collection_complete)
	b.on_minesweeper_collection_complete.connect(on_minesweeper_collection_complete)
	b.building_placed.connect(on_building_placed)

# Called when the node enters the scene tree for the first time.
func _ready():
	for key in BuildingData.data.keys():
		icons[key] = load(BuildingData.data[key]["icon_path"])
	
	# place board in center with correct offset accounting for tile size and board size
	generate_board(0)
	responsive_ui.enter_play_mode()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	responsive_ui.set_resource_count(ResourceData.Resources.POPULATION, population)
	responsive_ui.set_resource_count(ResourceData.Resources.STONE, stone)
	responsive_ui.set_resource_count(ResourceData.Resources.STEEL, steel)
	responsive_ui.set_resource_count(ResourceData.Resources.SLEDGEHAMMER, 5)
	responsive_ui.set_depth(depth + 1)
	
	if get_current_board():
		responsive_ui.set_flag_count(get_current_board().flags)
		responsive_ui.set_enter_build_mode_disabled(!can_enter_build_mode())
		
		responsive_ui.set_descend_disabled(!stairs_placed())
	
	if !help_text_is_overriden:
		help_text_bar.text = "Press \'H\' for help overlay"


func can_enter_build_mode() -> bool:
	return get_current_board().tiles_uncovered != 0

func ability(ability_name: AbilityData.Type):
	if get_current_board().mine_exploded:
		return
	print("func ability, ability_name: ", ability_name)
	if ability_name == AbilityData.Type.DESTROY && ability_destroy < 1:
		print("can't use destroy, out of uses")
		return
	elif ability_name == AbilityData.Type.ARMOR:
		if get_current_board().armor_active:
			# Prevent player from stacking armor uses on a single turn
			return
		elif ability_armor < 1:
			print("can't use armor, out of uses")
			return
		else:
			ability_armor -= 1
	elif ability_name == AbilityData.Type.DOWSE:
		if ability_dowse < 1:
			print("can't use dowse, out of uses")
			return
		elif get_current_board().flags < 1:
			print("can't use dowse, out of flags")
			return
		
	get_current_board().queue_ability(ability_name)

func start_placement(type: BuildingData.Type):
	state = State.Placing
	print("func start_placement, building_name: ", type)
	get_current_board().queue_building(type)
	responsive_ui.enter_place_mode()

func on_building_placed():
	responsive_ui.on_building_placed()

func next_level():
	get_current_board().queue_free()
	
	print("MAIN SCENE RECEIVED NEXT LEVEL CALL")
	depth += 1
	
	state = State.Play
	
	generate_board(depth)
	responsive_ui.enter_play_mode()

func _on_responsive_ui_enter_build_mode_pressed():
	if state != State.Build:
		get_current_board().enter_build_mode()
	else:
		push_error("ALREADY IN BUILD MODE but end level button pressed")


func on_mine_animation_complete():
	get_tree().paused = true
	SoundManager.play_negative()
	if population > 0:
		mine_hit_popup.visible = true
		greyout.visible = true
	elif population == 0:
		game_over.show()
		greyout.show()

func _on_mine_hit_restart_level_pressed():
	mine_hit_popup.visible = false
	greyout.visible = false
	get_current_board().queue_free()
	generate_board(depth)
	get_tree().paused = false


#func _on_page_up_button_pressed():
#	SoundManager.play_page_turn_sound()
#	page_one.show()
#	page_down.disabled = false
#	page_two.hide()
#	page_up.disabled = true
#
#func _on_page_down_button_pressed():
#	SoundManager.play_page_turn_sound()
#	page_one.hide()
#	page_down.disabled = true
#	page_two.show()
#	page_up.disabled = false

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
	get_current_board().placing = false
	help_text_is_overriden = false
	choose_active.show()
	greyout.show()
	get_tree().paused = true

func _on_choose_active_ability_chosen(ability_name):
	choose_active.hide()
	greyout.hide()
	get_tree().paused = false
	if ability_name == "crane":
		ability_destroy_max += 1
	elif ability_name == "armor":
		ability_armor_max += 1
	elif ability_name == "scanner":
		ability_dowse_max += 1
		
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
