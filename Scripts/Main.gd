extends Node2D
class_name GameController

@onready var overworld = $OverworldMap

@onready var responsive_ui: ResponsiveUI = $ResponsiveUICanvas/ResponsiveUI

@onready var camera: CameraController = $Camera2D

@onready var canvas_modulate = $CanvasModulate
@onready var pointlight = $PointLight2D

@onready var fog = $Fog
@onready var shared_tilemap: SharedTileMap = $TileMap
@onready var play_area_border = $PlayAreaBorder



var board_prefab = preload("res://Prefabs/board.tscn")

var grid_line_prefab: PackedScene = preload("res://Prefabs/GridLine.tscn")

var tier = 1
var depth_by_tier = {}
var available_buildings: Array[BuildingData.Type] = []
var available_resources: Array[ResourceData.Resources] = []
 
var ability_charge_maximums = { AbilityData.Type.ARMOR: 0, AbilityData.Type.DESTROY: 0, AbilityData.Type.DOWSE: 0 }
var ability_charge_counts = {}

var total_workshop_count = 0

var overlay_toggled: bool = false

var current_board

var icons = {}

var last_checked_resource_amounts = {}

var state = State.Play

var prev_generated_boards

enum State {
	Play,
	Build,
	Placing
}

func generate_board(difficulty: int, room_id: int) -> Board:
	var overworld_room = overworld.rooms[room_id]
	
	# Reset all ability counts
	ability_charge_counts = ability_charge_maximums.duplicate()
	responsive_ui.update_abilities(ability_charge_counts, ability_charge_maximums)
	var b: Board = board_prefab.instantiate()
	
	add_child(b)
	
	canvas_modulate.visible = tier > 1
	pointlight.visible = tier > 1

	var room_origin = overworld.rooms[room_id].origin
	var mine_count = roundi(.11111 * overworld_room.size.x * overworld_room.size.y)
	b.init_board(overworld_room.size.x, overworld_room.size.y, mine_count, tier, shared_tilemap, room_origin)
	
	overworld.assign_board(room_id, b)
	b.position = room_origin * Globals.TILE_SIZE

	b.mine_animation_complete.connect(on_mine_animation_complete)
	b.wonder_placed.connect(on_wonder_placed)
	b.workshop_placed.connect(on_workshop_placed)
	b.workshop_destroyed.connect(on_workshop_destroyed)
	b.on_building_collection_complete.connect(on_building_collection_complete)
	b.on_minesweeper_collection_complete.connect(on_minesweeper_collection_complete)
	
	b.placing_building_instantiated.connect(on_placing_building_instantiated)
	b.building_placed.connect(on_building_placed)
	
	b.building_right_click_cancelled.connect(_on_responsive_ui_cancel_placement_pressed)
	
	b.building_selected.connect(on_building_selected)
	b.building_deselected.connect(on_building_deselected)
	
	b.ability_complete.connect(on_ability_completed)
	
	b.tile_uncover_event_complete.connect(on_tile_uncover_event_complete)
	b.tile_flagged_event_complete.connect(on_tile_uncover_event_complete)
	
	b.lock()
	

	var board_center = b.get_center_global_position()
	
	fog.update_fog(board_center, overworld_room.size.x)
	
	return b


func update_current_board(board: Board):
	if get_current_board() != null:
		get_current_board().deactivate()
	
	current_board = board
	board.activate()
	
	move_child(camera, -1)
	camera.smooth_reset(board.get_center_global_position())
	
	play_area_border.set_area(board.global_position, board.get_size_global_position())

# Called when the node enters the scene tree for the first time.
func _ready():
#	randomize()
#	var random_seed = randi()
#	seed(random_seed)
#	print("Seed: %d" % random_seed)
	seed(975027303)
	
	
	depth_by_tier[tier] = 0
	for key in BuildingData.data.keys():
		icons[key] = load(BuildingData.data[key]["icon_path"])
	
	# place board in center with correct offset accounting for tile size and board size
	test_new_tier()
	
	

	var starting_origin =  overworld.max_size / 2 - Vector2i(overworld.start_room_size / 2, overworld.start_room_size / 2)
	var start_room_size = overworld.start_room_size
	var starting_room_id = overworld.generate_room(start_room_size, starting_origin)

	
	update_current_board(generate_board(0, starting_room_id))
	camera.reset(get_current_board().get_center_global_position(), get_current_board().get_size_global_position())
	
	shared_tilemap.fill(Rect2i(starting_origin - Vector2i(20, 20), Vector2i(40, 40)))


	responsive_ui.update_buildings(available_buildings)
	responsive_ui.update_resources(available_resources)
	responsive_ui.update_abilities(ability_charge_counts, ability_charge_maximums)
	responsive_ui.enter_play_mode()
	
	last_checked_resource_amounts = Resources.get_amounts_copy()
	
	create_grid_lines()

func test_new_tier():
	#TESTING
	# Keep this commented except for when jumping straight to a higher tier for testing
	# TODO: Re-Comment this when done testing

#	tier = 2
#	depth_by_tier[tier] = 0
#	available_buildings.append_array(BiomeData.get_buildings(1))
#	available_buildings.append_array(BiomeData.get_resources(1))
	available_buildings.append_array(BiomeData.get_buildings(tier))
	available_resources.append_array(BiomeData.get_resources(tier))

func get_depth() -> int:
	return depth_by_tier[tier]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pointlight.position = camera.position
	
	for type in ResourceData.Resources.values():
		if last_checked_resource_amounts[type] != Resources.get_amount(type):
			responsive_ui.set_resource_count(type, Resources.get_amount(type))

	last_checked_resource_amounts = Resources.get_amounts_copy()

	responsive_ui.set_depth(get_depth() + 1)
	
	if get_current_board():
		responsive_ui.set_flag_count(get_current_board().flags)
		responsive_ui.set_enter_build_mode_disabled(!can_enter_build_mode())
		
		responsive_ui.set_descend_disabled(!stairs_placed())
		responsive_ui.set_stairs_placed(stairs_placed())
	
	if (Input.is_action_just_pressed("Test_1")):
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://Screenshot.png")

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

func next_level(chosen_room_id: int):

	update_current_board(overworld.rooms[chosen_room_id].board)
	
	print("MAIN SCENE RECEIVED NEXT LEVEL CALL")
	depth_by_tier[tier] += 1
	
	state = State.Play
	
	reset_available_for_tier_data()
	
	responsive_ui.update_buildings(available_buildings)
	responsive_ui.update_resources(available_resources)
	responsive_ui.enter_play_mode()

func _on_responsive_ui_enter_build_mode_pressed():
	if state == State.Build:
		push_error("ALREADY IN BUILD MODE but end level button pressed")
		return
	
	
	responsive_ui.hide_enter_build_mode()
	get_current_board().enter_build_mode()
	
	var room_id = get_current_board().overworld_room_id
	var origin_room = overworld.rooms[room_id]
	# Interpolate our desired room size from map center to map boundaries. TODO: consider how an infinite map might affect this
	var t = Vector2(origin_room.origin).distance_to(Vector2(overworld.rooms[0].origin)) / Vector2(overworld.max_size / 2.0).length()
	var target_size = roundi((lerp(overworld.min_room_size, overworld.max_room_size, t)))

	var new_room_ids = [] 
	if room_id != 0:
		new_room_ids = overworld.generate_choices(room_id, target_size)
	else:
		var start_room_size = overworld.start_room_size
		var starting_origin =  overworld.max_size / 2 - Vector2i(overworld.start_room_size / 2, overworld.start_room_size / 2)
		new_room_ids = [
			overworld.generate_room(start_room_size, starting_origin + Vector2i(0, -start_room_size), 0),
			overworld.generate_room(start_room_size, starting_origin + Vector2i(0, start_room_size), 0),
			overworld.generate_room(start_room_size, starting_origin + Vector2i(start_room_size, 0), 0),
			overworld.generate_room(start_room_size, starting_origin + Vector2i(-start_room_size, 0), 0)
		]
	
	prev_generated_boards = []
	
	for id in new_room_ids:
		var board = generate_board(get_depth(), id)
		prev_generated_boards.append(board)


func on_mine_animation_complete():
	SoundManager.play_negative()
	var pop = Resources.get_amount(ResourceData.Resources.POPULATION)
	
	if pop > 0:
		responsive_ui.show_mine_hit_popup(_on_mine_hit_restart_level_pressed)
	elif pop == 0:
		print_debug("GAME OVER - LOSS")

func _on_mine_hit_restart_level_pressed():
	var room_id = get_current_board().overworld_room_id
	var prev_board = get_current_board()
	update_current_board(generate_board(get_depth(), room_id))
	prev_board.queue_free()
	shared_tilemap.fill(get_current_board().get_boundaries_rect())

func stairs_placed():
	return get_current_board().stairs_placed

func get_current_board() -> Board:
	return current_board

func _on_responsive_ui_descend_pressed(force: bool = false):
	if !force && !get_current_board().are_all_buildings_being_exploited():
		responsive_ui.show_floor_descend_warning(_on_responsive_ui_descend_pressed.bind(true))
		return
	get_current_board().collect_resources()

func on_resource_collection_complete():
	if (depth_by_tier[tier] == -1):
		responsive_ui.show_transition(tier)
	else:
		show_unlock_boxes()

func on_transition_to_next_tier_midpoint():
	show_unlock_boxes()


func show_unlock_boxes():
	for room_id in overworld.rooms.keys():
		var room = overworld.rooms[room_id]
		if room.board != null && room.board.is_locked():
			responsive_ui.spawn_board_unlock_panel(room.board)

func _on_win_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene() # TODO: GO TO TITLE SCREEN

func _on_loss_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()  # TODO: GO TO TITLE SCREEN

func on_wonder_placed():
	SoundManager.play_positive()
	print_debug("GAME OVER - WIN!")

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
			
		if overlay_toggled:
			var new_color = Color.WHITE
			new_color.a = 0.1
			modulate = new_color
		else:
			modulate = Color.WHITE

func _on_end_level_btn_mouse_entered():
		SoundManager.play_negative()

func on_building_collection_complete():
	on_resource_collection_complete()

func on_minesweeper_collection_complete():
	print("collect_complete")
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

func reset_available_for_tier_data():
	available_buildings = []
	available_resources = []
	for i in tier + 1:
		available_buildings.append_array(BiomeData.get_buildings(i))
		available_resources.append_array(BiomeData.get_resources(i))

func on_tile_uncover_event_complete():
	if get_current_board().is_cleared():
		_on_responsive_ui_enter_build_mode_pressed()


func _on_responsive_ui_board_unlock_pressed(board: Board):
	for type in board.unlock_costs.keys():
		Resources.update_amount(type, -board.unlock_costs[type])
	next_level(board.overworld_room_id)


func create_grid_lines():
	var offset = Globals.TILE_SIZE_VECTOR
	shared_tilemap
#	var min_fade_pos = to_global(shared_tilemap.map_to_local(tilemap_origin_cell_pos)) - offset
#	var max_fade_pos = min_fade_pos + Vector2(Globals.TILE_SIZE * columns, Globals.TILE_SIZE * rows) + offset
#
	for i in range(1, overworld.max_size.y):
		var instance = grid_line_prefab.instantiate()
		add_child(instance)
		instance.position.x = 0
		instance.position.y = Globals.TILE_SIZE * i
		instance.material.set_shader_parameter("speed", randf_range(0.01, 0.025) * (-1.0 if i % 2 == 0 else 1.0))
#		instance.material.set_shader_parameter("min_fade_pos", min_fade_pos)
#		instance.material.set_shader_parameter("max_fade_pos", max_fade_pos)
		
	for i in range(1, overworld.max_size.x):
		var instance = grid_line_prefab.instantiate()
		add_child(instance)
		instance.global_rotation_degrees = 90
		instance.position.x = Globals.TILE_SIZE * i
		instance.position.y = 360
		
		instance.material.set_shader_parameter("speed", randf_range(0.01, 0.025) * (-1.0 if i % 2 == 0 else 1.0))
#		instance.material.set_shader_parameter("min_fade_pos", min_fade_pos)
#		instance.material.set_shader_parameter("max_fade_pos", max_fade_pos)
