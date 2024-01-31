extends Node2D
class_name BaseBuilding

signal right_click_cancelled
signal on_placed
signal on_selected(building: BaseBuilding)
signal on_deselected

@export var type: BuildingData.Type
@onready var sprite: Sprite2D = $Sprite2D
@onready var speech_bubble: SpeechBubble = $SpeechBubble

@onready var background_sprite: Sprite2D = $BG

@onready var board = get_parent()
@onready var main = board.get_parent()
@onready var gui_control = $Control

@onready var handle_arrows = $HandleArrows
@onready var cant_build_label = $CantBuildLabel
@onready var pointlight = $PointLight2D

var building_placement_material: ShaderMaterial = preload("res://Shaders/InvalidBuildingPlacement.tres")
var drawing_material: ShaderMaterial = preload("res://Shaders/EraserMaterial.tres")

const bg_offset := Vector2i(3, 3)

const collection_prefab: PackedScene = preload("res://UI/collection_effect.tscn")

const need_minecart_texture: Texture = preload("res://Assets/Buildings/minecart downscaled.png")
const need_lava_texture: Texture = preload("res://Assets/walltiles/LavaPoolDownscaled.png")

const TILE_SIZE = 64

var id: int
var size: int

# Only used if building is a LAVA moat, keeps track of which (if any) lava source tiles it is pathed to
var connected_lava_sources = []

var took_help_text_override = false

var state := State.Unplaced

var move_begin_offset = Vector2.ZERO

var mouse_in = false

var can_show_problem: bool = true

var touch_events = {}

var selection_event
var deselection_event

enum State {
	Unplaced,
	PlacedUnconfirmed,
	Moving,
	Confirmed,
	Selected
}

enum BuildingProblem {
	NO_MINECART,
	NO_LAVA
}

func set_type(value, icon):
	type = value
	size = BuildingData.data[type]["size"]
	gui_control.size = Vector2(TILE_SIZE, TILE_SIZE) * size
	speech_bubble.position.x = TILE_SIZE * size / 2.0 - (TILE_SIZE / 2.0)
	
	sprite.texture = icon
	handle_arrows.scale.x = size
	handle_arrows.scale.y = size
	if type == BuildingData.Type.LAVA:
		pointlight.visible = true

func snap_position(pos: Vector2) -> Vector2:
	var snapped =  Vector2(snapped(pos.x-TILE_SIZE/2, TILE_SIZE), snapped(pos.y-TILE_SIZE/2, TILE_SIZE))
	print("Pos: %s Snapped: %s" % [pos, snapped])
	return snapped
	

func _process(delta):
	if state == State.PlacedUnconfirmed:
		handle_arrows.visible = true
	else:
		handle_arrows.visible = false

	
	if state == State.Unplaced || state == State.Moving:
		var mouse = board.get_local_mouse_position()
		if state == State.Moving:
			mouse -= move_begin_offset
		
		# in-bounds with grid check
		var snapped = snap_position(mouse)
		position = snapped

		if !can_place(global_position):
			sprite.material = building_placement_material
			cant_build_label.visible = true
		else:
			sprite.material = null
			cant_build_label.visible = false
		
	if size == 1:
		background_sprite.visible = false
	else:
		background_sprite.position = bg_offset
		var cell_pos = board.world_to_cell(global_position)
		var region_x = bg_offset.x if cell_pos.x % 2 == 0 else 64 + bg_offset.x
		var region_y = bg_offset.y if cell_pos.y % 2 == 0 else 64 + bg_offset.y
		var region_w = size * TILE_SIZE - bg_offset.x * 2
		var region_h = size * TILE_SIZE - bg_offset.y * 2
		background_sprite.region_rect = Rect2(region_x, region_y, region_w, region_h)
		
	if requires_minecart_adjacency():
		var next_to_minecart = next_to_minecart()
		toggle_problem(!next_to_minecart, BuildingProblem.NO_MINECART)
		
		var mouse_pos = get_local_mouse_position()
		var mouse_in_bounds = mouse_pos.x >= 0 && mouse_pos.y >= 0 && mouse_pos.x < TILE_SIZE * size && mouse_pos.y < TILE_SIZE * size
		if !next_to_minecart && !main.help_text_is_overriden && mouse_in_bounds:
			main.help_text_bar.text = "Building will not earn resources when you descend to next floor. Build a minecart next to this building."
			main.help_text_is_overriden = true
			took_help_text_override = true
		elif took_help_text_override && !mouse_in_bounds:
			main.help_text_is_overriden = false
			took_help_text_override = false


func toggle_problem(has_problem: bool, reason: BuildingProblem = BuildingProblem.NO_MINECART):
	if has_problem:
		match reason:
			BuildingProblem.NO_MINECART:
				speech_bubble.set_texture(need_minecart_texture)
			BuildingProblem.NO_LAVA:
				speech_bubble.set_texture(need_lava_texture)
	
	speech_bubble.set_revealed(has_problem && can_show_problem, 0.1 if !can_show_problem else 0.5)


func can_place(placement_position: Vector2):
	if (type == BuildingData.Type.LAVA || type == BuildingData.Type.FORGE) && !next_to_lava():
		return false
	return board.can_place_at_position(placement_position, size)

func requires_minecart_adjacency():
	return type == BuildingData.Type.HOUSE || type == BuildingData.Type.QUARRY

func requires_lava_adjacency():
	return type == BuildingData.Type.FORGE

func next_to_minecart() -> bool:
	return board.building_is_next_to_minecart(self) || board.player_placing_minecart_next_to_building(self)
	
func next_to_lava() -> bool:
	return board.building_is_next_to_lava(self) 

func place(world_pos: Vector2):
	global_position = snap_position(world_pos)
	state = State.PlacedUnconfirmed
	sprite.material = null
	on_placed.emit()

func set_building_visibility(val: bool) -> void:
	# used by lava moat tile to hide building in favor of lava moat tile
	sprite.visible = val

func _unhandled_input(event):
	if PlatformUtil.isMobile():
		_handle_touch_input(event)
	else:
		_handle_mouse_input(event)

func _handle_touch_input(event):
	if !event is InputEventScreenTouch && !event is InputEventScreenDrag:
		return
	
	var event_world_position = get_global_mouse_position()
	
	var bounds = Rect2(global_position, Vector2(TILE_SIZE, TILE_SIZE) * size)
	var in_bounds = bounds.has_point(event_world_position)

	
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_events[event.index] = event
			if !DragOrZoomEventManager.drag_or_zoom_happening() && in_bounds:
				if touch_events.size() == 1 && state == State.PlacedUnconfirmed:
					enter_move_state()
		else:
			touch_events.erase(event.index)
			if touch_events.size() == 0 && !DragOrZoomEventManager.drag_or_zoom_happening() && in_bounds:
				if state == State.Confirmed:
					select(event)
				elif state == State.Selected:
					deselect(event)
			
			if state == State.Moving && DragOrZoomEventManager.drag_began_in_unconfirmed_building:
				exit_move_state()
	if event is InputEventScreenDrag && !DragOrZoomEventManager.drag_blocked:
		touch_events[event.index] = event

func _handle_mouse_input(event):
	if !mouse_in:
		return 
	
	# Left-click to place building logic
	if event is InputEventMouseButton && state == State.Unplaced:
		if event.is_action_pressed("left_click"):
			if !can_place(global_position):
				SoundManager.play_negative()

			if type == BuildingData.Type.STAIRCASE and board.stairs_placed:
				main.help_text_bar.text = "Stairs already placed! Can't have more than one staircase per floor"
				print("Stairs already placed!")
			if can_place(global_position):
				place(global_position)
				
				return
		elif event.is_action_pressed("right_click"):
			right_click_cancelled.emit()
	if state == State.PlacedUnconfirmed:
		if event is InputEventMouseButton and event.is_action_pressed("left_click"):
			enter_move_state()
	
	if state == State.Moving:
		if event is InputEventMouseButton and event.is_action_released("left_click") and DragOrZoomEventManager.drag_began_in_unconfirmed_building:
			exit_move_state()

	if event is InputEventMouseButton and event.is_action_released("left_click") and !DragOrZoomEventManager.drag_or_zoom_happening():
		if state == State.Confirmed:
			select(event)
		elif state == State.Selected:
			deselect(event)

func enter_move_state():
	DragOrZoomEventManager.drag_began_in_unconfirmed_building = true
	state = State.Moving
	move_begin_offset = Vector2.ZERO
	var reference_pos = position + Vector2(TILE_SIZE, TILE_SIZE)
	while (board.get_local_mouse_position().x - move_begin_offset.x > reference_pos.x):
		move_begin_offset.x += TILE_SIZE
	while (board.get_local_mouse_position().y - move_begin_offset.y > reference_pos.y):
		move_begin_offset.y += TILE_SIZE

func exit_move_state():
	state = State.PlacedUnconfirmed
	move_begin_offset = Vector2.ZERO
	DragOrZoomEventManager.drag_began_in_unconfirmed_building = false

func select(event):
	if event != null && event == deselection_event:
		return
	state = State.Selected
	selection_event = event
	on_selected.emit(self)

func deselect(event):
	if event != null && event == selection_event:
		return
	
	state = State.Confirmed
	deselection_event = event
	on_deselected.emit()

func confirm_placement():
	state = State.Confirmed
	
	can_show_problem = false
	sprite.material = drawing_material.duplicate()
	var tween = get_tree().create_tween().bind_node(self)
	tween.tween_method(func(val): sprite.material.set_shader_parameter("progress", val), 1.1, 0, 0.5)
	tween.tween_callback(func(): 
		sprite.material = null
		can_show_problem = true
	)
	cant_build_label.visible = false

func cancel_placement():
	# Handling for specific building logic on cancel
	if type == BuildingData.Type.LAVA:
		connected_lava_sources = []
		board.refresh_lava_connections()
	queue_free()

func play_collection_animation(lifespan_seconds: float, icon_path: String):
	var instance = collection_prefab.instantiate()
	add_child(instance)
	var amount = 0
	var data = BuildingData.data[type]
	
	#TODO: Allow for multiple different resources to be collected from a building?
	
	var stone = BuildingData.get_cost(type, ResourceData.Resources.STONE)
	var pop =  BuildingData.get_cost(type, ResourceData.Resources.POPULATION)
	var steel = BuildingData.get_cost(type, ResourceData.Resources.STEEL)
	
	if stone < 0:
		amount = -stone
	if steel < 0:
		amount = -steel
	if pop < 0:
		amount = -pop
	
	instance.init(amount, lifespan_seconds, icon_path)
	instance.global_position = global_position + (Vector2(TILE_SIZE, TILE_SIZE) * size / 2.0) + Vector2(0, -16)

func _on_control_mouse_entered():
	mouse_in = true

func _on_control_mouse_exited():
	mouse_in = false
