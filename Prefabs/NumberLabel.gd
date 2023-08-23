extends Sprite2D

@export var textures: Array[Texture] = []

func set_number(number: int):
	texture = textures[number - 1]
