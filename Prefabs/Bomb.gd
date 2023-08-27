extends Sprite2D

signal animation_complete()

func finish():
	animation_complete.emit()
