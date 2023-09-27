extends Control

@export var main: Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if main.build_mode:
		show()
	else:
		hide()
