extends ScrollContainer

# Allows you to scroll a scroll container by dragging.
# Includes momentum.
var dragging = false

func on_tapped(local_position: Vector2):
	var tap_listeners = get_tree().get_nodes_in_group("scroll_container_tap_event_listener")
	for tap_listener in tap_listeners:
		if is_ancestor_of(tap_listener):
			#https://docs.godotengine.org/en/stable/tutorials/2d/2d_transforms.html
			# Convert local_position to canvas coordinate. global_rect uses canvas coordinates
			var child: Control = tap_listener
			var canvas_pos = get_global_transform() * local_position
			if child.get_global_rect().has_point(canvas_pos):
				tap_listener.handle_tap()

func _on_gui_input(event):
	if event is InputEventScreenTouch:
		if !event.pressed && !dragging:
			on_tapped(event.position)
	elif event.is_action_released("left_click"):
		on_tapped(event.position)


func _on_scroll_started():
	dragging = true


func _on_scroll_ended():	
	dragging = false

func _on_mouse_entered():
	DragOrZoomEventManager.zoom_blocked = true

func _on_mouse_exited():
	DragOrZoomEventManager.zoom_blocked = false


func _on_hidden():
	DragOrZoomEventManager.zoom_blocked = false
