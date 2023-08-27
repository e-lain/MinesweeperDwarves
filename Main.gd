extends Node2D

@onready var depth_label = $CanvasLayer/UI/Depth
@onready var population_label = $CanvasLayer/UI/Resources/PopulationBox/Population
@onready var stone_label =$CanvasLayer/UI/Resources/StoneBox/Stone
@onready var steel_label = $CanvasLayer/UI/Resources/SteelBox/Steel
@onready var mine_hit_popup = $CanvasLayer/MineHitPopup
@onready var greyout = $CanvasLayer/ColorRect
@onready var enter_build_mode_button = $CanvasLayer/UI/EndLevelBtn

@onready var destroy_popup = $CanvasLayer/AbilityMenu/DestroyPopup
@onready var armor_popup = $CanvasLayer/AbilityMenu/ArmorPopup
@onready var dowse_popup = $CanvasLayer/AbilityMenu/DowsePopup

@onready var page_one = $CanvasLayer/BuildMenu/Page1
@onready var page_two = $CanvasLayer/BuildMenu/Page2
@onready var page_up = $CanvasLayer/BuildMenu/PageUpButton
@onready var page_down = $CanvasLayer/BuildMenu/PageDownButton

@onready var help_overlay_play = $CanvasLayer/HelpOverlayPlay
@onready var help_overlay_build = $CanvasLayer/HelpOverlayBuild
@onready var help_text_bar = $CanvasLayer/UI/ContextLabel
var help_text_is_overriden: bool = false

@onready var next_floor_button = $CanvasLayer/UI/NextFloorBtn

@onready var game_over = $CanvasLayer/GameOver
@onready var you_win = $CanvasLayer/YouWin

@onready var choose_active = $CanvasLayer/ChooseActive

var Board = preload("res://board.tscn")

var build_mode: bool = false

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

var boards = [] # Note, some of these may be null references because we queue_free() boards that have hit a bomb

signal queue_ability(ability_name)
signal queue_building(building_type: BuildingData.Type)

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
	add_child(b)
	
	if difficulty == 0:
		b.init_board(6,6,4)
	elif difficulty == 1:
		b.init_board(7,7,5)
	elif difficulty == 2:
		b.init_board(8,8,7)
	elif difficulty == 3:
		b.init_board(9,9,9)
	else:
		b.init_board(10,10,10)
		
	var center = get_viewport_rect().size/2
	var offset = Vector2(center.x-(b.rows * b.TILE_SIZE/2), center.y-(b.columns * b.TILE_SIZE/2))
	b.position = offset
	b.create_grid_lines()
	b.mine_animation_complete.connect(on_mine_animation_complete)
	b.wonder_placed.connect(on_wonder_placed)
	b.workshop_placed.connect(on_workshop_placed)
	b.on_building_collection_complete.connect(on_building_collection_complete)
	b.on_minesweeper_collection_complete.connect(on_minesweeper_collection_complete)
	boards.push_back(b)

# Called when the node enters the scene tree for the first time.
func _ready():
	# place board in center with correct offset accounting for tile size and board size
	generate_board(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	population_label.text = "x %d" % [population]
	stone_label.text = "x %d" % [stone]
	depth_label.text = "Depth: %d" % [depth + 1]
	steel_label.text = "x %d" % [steel]
	
	if get_current_board():
		$CanvasLayer/UI/Flags.text = "Flags: " + str(get_current_board().flags)
		if get_current_board().tiles_uncovered == 0:
			enter_build_mode_button.disabled = true
		else:
			enter_build_mode_button.disabled = false
		
		if stairs_placed():
			next_floor_button.show()
		else:
			next_floor_button.hide()
	
	if !help_text_is_overriden:
		help_text_bar.text = "Press \'H\' for help overlay"

func ability(ability_name):
	if get_current_board().mine_exploded:
		return
	print("func ability, ability_name: ", ability_name)
	if ability_name == "destroy" && ability_destroy < 1:
		print("can't use destroy, out of uses")
		return
	elif ability_name == "armor":
		if boards[len(boards)-1].armor_active:
			# Prevent player from stacking armor uses on a single turn
			return
		elif ability_armor < 1:
			print("can't use armor, out of uses")
			return
		else:
			ability_armor -= 1
	elif ability_name == "dowse":
		if ability_dowse < 1:
			print("can't use dowse, out of uses")
			return
		elif boards[len(boards)-1].flags < 1:
			print("can't use dowse, out of flags")
			return
		
	boards[len(boards)-1]._on_ability_queue(ability_name)

func build(type: BuildingData.Type):
	print("func build, building_name: ", type)
	queue_building.emit(type)

func next_level():
	var cur_board = get_current_board()
	cur_board.placing = false
	cur_board.clearing_tile = false
	cur_board.hide()	
	
	print("MAIN SCENE RECEIVED NEXT LEVEL CALL")
	depth += 1
	generate_board(depth)
	enter_build_mode_button.show()
	_on_page_up_button_pressed()

func _on_end_level_btn_pressed():
	if get_current_board().build_mode == false:
		get_current_board().enter_build_mode()
		enter_build_mode_button.hide()
		print("MANUALLY ENTERING BUILD MODE")
	else:
		print("ALREADY IN BUILD MODE")

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


func _on_page_up_button_pressed():
	SoundManager.play_page_turn_sound()
	page_one.show()
	page_down.disabled = false
	page_two.hide()
	page_up.disabled = true

func _on_page_down_button_pressed():
	SoundManager.play_page_turn_sound()
	page_one.hide()
	page_down.disabled = true
	page_two.show()
	page_up.disabled = false

func stairs_placed():
	return get_current_board().stairs_placed

func get_current_board():
	return boards[boards.size() - 1]

func _on_next_floor_btn_pressed():
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
	boards[len(boards)-1].placing = false
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
			
		if boards[len(boards)-1].build_mode == false:
			help_overlay_play.visible = !help_overlay_play.visible
		elif boards[len(boards)-1].build_mode == true:
			help_overlay_build.visible = !help_overlay_build.visible
			
		if overlay_toggled:
			var new_color = Color.WHITE
			new_color.a = 0.1
			modulate = new_color
		else:
			modulate = Color.WHITE

func _on_end_level_btn_mouse_entered():
	if enter_build_mode_button.disabled && !help_text_is_overriden:
		SoundManager.play_negative()
		help_text_is_overriden = true
		help_text_bar.text = "Can't enter build mode until at least one tile is cleared!"


func _on_end_level_btn_mouse_exited():
	help_text_is_overriden = false

func on_building_collection_complete():
	on_resource_collection_complete()

func on_minesweeper_collection_complete():
	pass
#	on_resource_collection_complete()
