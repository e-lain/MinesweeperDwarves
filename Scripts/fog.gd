extends Node2D

@export var fog_width = 1080
@export var fog_height = 1080
@export var light_width = 300
@export var light_height = 300
@export var debounce_time = 0.01
@export var fill_color = Color.BLACK

var time_since_last_fog_update = 0.0

const LIGHT_TEXTURE = preload("res://Assets/Test/White32.png")

@onready var fog = $Fog

var fog_image: Image
var fog_texture: ImageTexture
var light_image: Image
var light_offset: Vector2
var light_rect: Rect2

func _ready():
	# get Image from CompressedTexture2D and resize it
	light_image = LIGHT_TEXTURE.get_image()
	light_image.convert(Image.FORMAT_RGBA8)
	light_image.resize(light_width, light_height)
	
	light_offset = Vector2(light_width / 2.0, light_height / 2.0)

	fog_image = Image.create(fog_width, fog_height, false, Image.FORMAT_RGBA8)
	fog_image.fill(fill_color)
	fog_texture = ImageTexture.create_from_image(fog_image)
	fog.texture = fog_texture
	
	light_rect = Rect2(Vector2.ZERO, light_image.get_size())
	
func update_fog(new_grid_position, size):
	var pos = to_local(new_grid_position)
	var new_rect = Rect2(Vector2.ZERO, light_rect.size * size)
	fog_image.blend_rect(light_image, new_rect, pos - light_offset)
	fog_texture.update(fog_image)
