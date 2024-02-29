class_name BuildingEntityView extends BoardEntityView

signal right_click_cancelled
signal on_placed
signal on_selected(building: BaseBuilding)
signal on_deselected

var type: BuildingData.Type
var building_data: BuildingDataResource

@onready var speech_bubble: SpeechBubble = $SpeechBubble

@onready var background_sprite: Sprite2D = $BG

@onready var gui_control = $Control

@onready var handle_arrows = $HandleArrows
@onready var cant_build_label = $CantBuildLabel
@onready var pointlight = $PointLight2D

var building_placement_material: ShaderMaterial = preload("res://Shaders/InvalidBuildingPlacement.tres")
var drawing_material: ShaderMaterial = preload("res://Shaders/EraserMaterial.tres")

const bg_offset: Vector2i = Vector2i(3, 3)

const collection_prefab: PackedScene = preload("res://UI/collection_effect.tscn")

const need_minecart_texture: Texture = preload("res://Assets/Buildings/minecart downscaled.png")
const need_lava_texture: Texture = preload("res://Assets/walltiles/LavaPoolDownscaled.png")

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

func init(model: BoardEntityModel):
	super(model)
	if !(model is BaseBuildingEntityModel):
		push_error("Creating Building Entity View with incorrect Model")
	
	
	building_data = (model as BaseBuildingEntityModel).get_building_data()
	type = building_data.type

	var size: Vector2i = building_data.bounding_rect_dimensions
	
	gui_control.size = Globals.TILE_SIZE * size
	speech_bubble.position.x = Globals.TILE_SIZE * size.x / 2.0 - (Globals.TILE_SIZE / 2.0)
	cant_build_label.position.x = Globals.TILE_SIZE * size.x / 2.0 - (cant_build_label.size.x / 2.0)
	cant_build_label.position.y = Globals.TILE_SIZE * size.y
	
	sprite.texture = building_data.icon
	handle_arrows.scale = size
	
	if type == BuildingData.Type.LAVA:
		pointlight.visible = true

func _process(delta):
	if state != State.Confirmed:
		sprite.modulate.a = 0.5
	else:
		sprite.modulate.a = 1.0
	
	if state == State.PlacedUnconfirmed:
		handle_arrows.visible = true
	else:
		handle_arrows.visible = false

	
	if state == State.Unplaced || state == State.Moving:
		var mouse = get_local_mouse_position()
		if state == State.Moving:
			mouse -= move_begin_offset
		
		# in-bounds with grid check
		var snapped = Globals.snap_position(mouse)
		position = snapped

		if !can_place():
			sprite.material = building_placement_material
			cant_build_label.visible = true
		else:
			sprite.material = null
			cant_build_label.visible = false
	
	var size = building_data.bounding_rect_dimensions
	
	if size == Vector2i.ONE:
		background_sprite.visible = false
	else:
		background_sprite.position = bg_offset
		var cell_pos = _model.get_bounding_cell_rect().position
		var region_x = bg_offset.x + ((cell_pos.x % 8) * Globals.TILE_SIZE)
		var region_y = bg_offset.y + ((cell_pos.y % 8) * Globals.TILE_SIZE)
		var region_w = size.x * Globals.TILE_SIZE - bg_offset.x * 2
		var region_h = size.y * Globals.TILE_SIZE - bg_offset.y * 2
		background_sprite.region_rect = Rect2(region_x, region_y, region_w, region_h)
	
	var problems = (_model as BaseBuildingEntityModel).get_collection_problems()
	if problems.size() > 0:
		toggle_problem(true, problems[0])
	else:
		toggle_problem(false)


func toggle_problem(has_problem: bool, reason: TileRequirement.RequirementProblem = TileRequirement.RequirementProblem.NoMinecart):
	if has_problem:
		match reason:
			TileRequirement.RequirementProblem.NoMinecart:
				speech_bubble.set_texture(need_minecart_texture)
			TileRequirement.RequirementProblem.NoLava:
				speech_bubble.set_texture(need_lava_texture)
	
	speech_bubble.set_revealed(has_problem && can_show_problem, 0.1 if !can_show_problem else 0.5)


## Returns true if the model indicates the building can be placed at the current position. False otherwise.
func can_place() -> bool:
	return (_model as BaseBuildingEntityModel).can_place()

func requires_minecart_adjacency():
	return type == BuildingData.Type.HOUSE || type == BuildingData.Type.QUARRY

func place():
	_model.place(_model.get_bounding_cell_rect())
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
	
	var size: Vector2i = _model.get_bounding_cell_rect().size
	
	var event_world_position: Vector2 = get_global_mouse_position()
	
	var bounds: Rect2 = Rect2(global_position, Vector2(Globals.TILE_SIZE, Globals.TILE_SIZE) * size.x)
	var in_bounds: bool = bounds.has_point(event_world_position)

	
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
			if !can_place():
				SoundManager.play_negative()
			if can_place():
				place()
				
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
	var reference_pos = position + Vector2(Globals.TILE_SIZE, Globals.TILE_SIZE)
	while (get_local_mouse_position().x - move_begin_offset.x > reference_pos.x):
		move_begin_offset.x += Globals.TILE_SIZE
	while (get_local_mouse_position().y - move_begin_offset.y > reference_pos.y):
		move_begin_offset.y += Globals.TILE_SIZE

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

func play_collection_animation(icon_path: String, collection_count: int = 0):
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
	
	instance.global_position = global_position + (Vector2(Globals.TILE_SIZE, Globals.TILE_SIZE) * size / 2.0) + Vector2(0, -16)
	instance.init(amount, icon_path, collection_count)

func _on_control_mouse_entered():
	mouse_in = true

func _on_control_mouse_exited():
	mouse_in = false
