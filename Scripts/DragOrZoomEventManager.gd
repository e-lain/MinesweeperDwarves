extends Node

var dragging: bool = false
var zooming: bool = false

var drag_began_in_unconfirmed_building: bool = false

var long_tap_started: bool = false
var long_tap_occurred: bool = false

func clear():
	dragging = false
	zooming = false

func drag_or_zoom_happening() -> bool:
	return dragging || zooming
