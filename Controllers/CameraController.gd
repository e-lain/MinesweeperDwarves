extends Camera2D
class_name CameraController

signal tap_complete(event: InputEventScreenTouch)
signal drag_complete

const FORCED_MOVE_SPEED: float = 1000.0

@export var min_zoom = 0.75
@export var max_zoom = 2
var zoom_sensitivity = 10
var zoom_speed = 0.05
var drag_speed = 1.0

# TODO: Split Mobile and Desktop controls to different classes? prolly good
# Mobile drag tracking
var events = {}
var last_drag_distance = 0

# Desktop drag tracking
var dragging := false
var absolute_drag_amount = Vector2.ZERO
var absolute_drag_min_threshold = 5


var forced_move_target_pos: Vector2
var forced_move_target_zoom: Vector2
var forced_move_tween: Tween

var state: State = State.DEFAULT

enum State {
	DEFAULT,
	FORCED_MOVE
}


func smooth_reset(target: Vector2):
	forced_move_target_pos = target
	forced_move_target_zoom = Vector2.ONE # TODO: Calculate this forreal
	state = State.FORCED_MOVE
	var duration = .4
	
	forced_move_tween = create_tween()
	forced_move_tween.tween_property(self, "position", forced_move_target_pos, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	forced_move_tween.parallel()
	forced_move_tween.tween_property(self, "zoom", forced_move_target_zoom, duration)
	forced_move_tween.tween_callback(func(): state = State.DEFAULT)

func reset(center: Vector2, board_size: Vector2):
	forced_move_tween.kill()
	position = center
	state = State.DEFAULT
	
#	var viewport_dimensions: Vector2 = get_viewport_rect().size
#	limit_left = center.x - board_size.x - viewport_dimensions.x / 2.0
#	limit_top = center.y - board_size.y - viewport_dimensions.y / 2.0
#	limit_right = center.x + board_size.x + viewport_dimensions.x / 2.0
#	limit_bottom = center.y + board_size.y + viewport_dimensions.y / 2.0
#
func _input(event):
	if state == State.FORCED_MOVE:
		return
	
	if event.is_action_released("left_click") && DragOrZoomEventManager.long_tap_occurred:
		DragOrZoomEventManager.long_tap_occurred = false
		dragging = false
		DragOrZoomEventManager.clear()
		get_viewport().set_input_as_handled()
	elif DragOrZoomEventManager.long_tap_occurred:
		get_viewport().set_input_as_handled()

func _unhandled_input(event):
	if PlatformUtil.isMobile():
		# Don't ask me how this shit works I'm a copypasta coder: https://kidscancode.org/godot_recipes/3.x/2d/touchscreen_camera/index.html
		if event is InputEventScreenTouch:
			if event.pressed:
				events[event.index] = event
				dragging = true
				absolute_drag_amount = Vector2.ZERO
			else:
				events.erase(event.index)
				if events.size() == 0:
					dragging = false
					if DragOrZoomEventManager.dragging:
						drag_complete.emit()
					else:
						tap_complete.emit(event)
					DragOrZoomEventManager.clear()
		if event is InputEventScreenDrag && !DragOrZoomEventManager.drag_blocked:
			events[event.index] = event
			if events.size() == 1 && !DragOrZoomEventManager.drag_began_in_unconfirmed_building: 
				absolute_drag_amount += Vector2(abs(event.relative.x), abs(event.relative.y))
				if absolute_drag_amount.length_squared() > absolute_drag_min_threshold:
					drag_camera(event.relative)
					DragOrZoomEventManager.dragging = true
					DragOrZoomEventManager.long_tap_started = false
			elif events.size() == 2:
				var drag_distance = events[0].position.distance_to(events[1].position)
				var zoom_factor = abs(drag_distance - last_drag_distance)
				if zoom_factor > zoom_sensitivity:
					var new_zoom = (1 - zoom_speed) if drag_distance < last_drag_distance else (1 + zoom_speed)
					zoom_camera(new_zoom)
					last_drag_distance = drag_distance
					DragOrZoomEventManager.zooming = true
					DragOrZoomEventManager.long_tap_started = false
		
	else:
		# Handle Drag
		if event.is_action_pressed("left_click"):
			dragging = true
			absolute_drag_amount = Vector2.ZERO
		
		elif event.is_action_released("left_click"):
			dragging = false
			if DragOrZoomEventManager.dragging:
				drag_complete.emit()
				get_viewport().set_input_as_handled()
			else:
				tap_complete.emit(event)
			
			DragOrZoomEventManager.dragging = false
		
		if event is InputEventMouseMotion and dragging and !DragOrZoomEventManager.drag_began_in_unconfirmed_building:
			absolute_drag_amount += Vector2(abs(event.relative.x), abs(event.relative.y))
			if absolute_drag_amount.length_squared() > absolute_drag_min_threshold:
#				print("Dragging!")
				drag_camera(event.relative)
				DragOrZoomEventManager.dragging = true
				DragOrZoomEventManager.long_tap_started = false
			
		# Handle scroll zoom
		if event is InputEventMouseButton and event.is_pressed() and !DragOrZoomEventManager.zoom_blocked:
			var mouse_event = event as InputEventMouseButton
			if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_camera(1.2)
			elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_camera(0.8)

func drag_camera(relative: Vector2):
	position -= relative.rotated(rotation) * (1.0/zoom.x) * drag_speed

func zoom_camera(delta):
	var new_zoom = clamp(zoom.x * delta, min_zoom, max_zoom)
	zoom = Vector2.ONE * new_zoom
	DragOrZoomEventManager.zoom_level = new_zoom
