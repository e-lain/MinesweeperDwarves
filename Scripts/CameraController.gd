extends Camera2D


@export var min_zoom = 0.5
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

func _unhandled_input(event):
	if PlatformUtil.isMobile():
		# Don't ask me how this shit works I'm a copypasta coder: https://kidscancode.org/godot_recipes/3.x/2d/touchscreen_camera/index.html
		if event is InputEventScreenTouch:
			if event.pressed:
				events[event.index] = event
			else:
				events.erase(event.index)
				if events.size() == 0:
					DragOrZoomEventManager.clear()
		if event is InputEventScreenDrag:
			events[event.index] = event
			if events.size() == 1:
				drag_camera(event.relative)
				DragOrZoomEventManager.dragging = true
			elif events.size() == 2:
				var drag_distance = events[0].position.distance_to(events[1].position)
				var zoom_factor = abs(drag_distance - last_drag_distance)
				if zoom_factor > zoom_sensitivity:
					var new_zoom = (1 - zoom_speed) if drag_distance < last_drag_distance else (1 + zoom_speed)
					zoom_camera(new_zoom)
					last_drag_distance = drag_distance
					DragOrZoomEventManager.zooming = true
		
	else:
		# Handle Drag
		if event.is_action_pressed("left_click"):
			dragging = true
			get_viewport().set_input_as_handled()

		elif event.is_action_released("left_click"):
			dragging = false
			get_viewport().set_input_as_handled()
			DragOrZoomEventManager.dragging = false
		
		if event is InputEventMouseMotion and dragging:
			drag_camera(event.relative)
			DragOrZoomEventManager.dragging = true
		
		# Handle scroll zoom
		if event is InputEventMouseButton and event.is_pressed():
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
