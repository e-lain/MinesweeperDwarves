extends Camera2D


@export var min_zoom = 0.5
@export var max_zoom = 2
var zoom_sensitivity = 10
var zoom_speed = 0.05
var drag_speed = 2.0

var events = {}
var last_drag_distance = 0


func _unhandled_input(event):
	if PlatformUtil.isMobile():
		# Don't ask me how this shit works I'm a copypasta coder: https://kidscancode.org/godot_recipes/3.x/2d/touchscreen_camera/index.html
		if event is InputEventScreenTouch:
			if event.pressed:
				events[event.index] = event
			else:
				events.erase(event.index)
		if event is InputEventScreenDrag:
			events[event.index] = event
			if events.size() == 1:
				position -= event.relative.rotated(rotation) * (1/zoom.x) * drag_speed
			elif events.size() == 2:
				var drag_distance = events[0].position.distance_to(events[1].position)
				if abs(drag_distance - last_drag_distance) > zoom_sensitivity:
					var new_zoom = (1 - zoom_speed) if drag_distance < last_drag_distance else (1 + zoom_speed)
					new_zoom = clamp(zoom.x * new_zoom, min_zoom, max_zoom)
					zoom = Vector2.ONE * new_zoom
					last_drag_distance = drag_distance
		
	else:
		if event is InputEventMouseButton and event.is_pressed():
			var mouse_event = event as InputEventMouseButton
			if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_by_multiple(1.2)
			elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_by_multiple(0.8)
		
func zoom_by_multiple(value):
	var new_zoom = zoom.x * value
	
	if new_zoom < min_zoom:
		new_zoom = min_zoom
	elif new_zoom > max_zoom:
		new_zoom = max_zoom
	zoom = Vector2(new_zoom, new_zoom)
