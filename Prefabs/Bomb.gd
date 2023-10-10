extends Sprite2D

signal animation_complete()

var type: BombData.Type

func set_type(bomb_type: BombData.Type):
	type = bomb_type
	self.texture = load(BombData.data[bomb_type].texture)

func finish():
	animation_complete.emit()
