extends Sprite2D


func set_area(origin: Vector2, size: Vector2):
	var offset: Vector2 =  size / 10.0
	material.set_shader_parameter("PlayAreaOrigin", origin - offset / 2.0)
	material.set_shader_parameter("PlayAreaSize", size + offset)
