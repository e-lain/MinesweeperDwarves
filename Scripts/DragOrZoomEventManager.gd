extends Node

var drag_blocked: bool = false
var zoom_blocked: bool = false

var dragging: bool = false
var zooming: bool = false

var drag_began_in_unconfirmed_building: bool = false

var long_tap_started: bool = false
var long_tap_occurred: bool = false


var zoom_level = 1

func clear():
	dragging = false
	zooming = false

func drag_or_zoom_happening() -> bool:
	return dragging || zooming


func get_zoom_level():
	return zoom_level
