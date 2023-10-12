extends Node

var dragging: bool = false
var zooming: bool = false

var drag_began_in_unconfirmed_building: bool = false

func clear():
	dragging = false
	zooming = false

func drag_or_zoom_happening() -> bool:
	return dragging || zooming
