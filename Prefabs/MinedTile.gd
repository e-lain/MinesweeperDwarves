extends Sprite2D

@onready var background_sprite = $BG

func _ready():
	visible = false

func init(_position: Vector2, tilesheet_sprite_coords:Vector2i, cell_position: Vector2i, origin_distance: int = 0):
	visible = true
	position = _position
	
	frame_coords = tilesheet_sprite_coords
	material = material.duplicate()
	background_sprite.material = background_sprite.material.duplicate()

	material.set_shader_parameter("frame_coords", tilesheet_sprite_coords);
	material.set_shader_parameter("frame_coxunts", Vector2(hframes, vframes));

	var bg_frame_counts: Vector2 = (background_sprite.texture.get_size() / Globals.TILE_SIZE).round()
	var bg_frame_coords: Vector2 = Vector2(cell_position.x % int(bg_frame_counts.x), cell_position.y % int(bg_frame_counts.y))
	var region_x: float = Globals.TILE_SIZE * bg_frame_coords.x
	var region_y: float = Globals.TILE_SIZE * bg_frame_coords.y
	var region_w: float = Globals.TILE_SIZE - 8
	var region_h: float = Globals.TILE_SIZE - 8
	background_sprite.region_rect = Rect2(region_x, region_y, region_w, region_h)
	
	background_sprite.material.set_shader_parameter("frame_coords", bg_frame_coords);
	background_sprite.material.set_shader_parameter("frame_counts", bg_frame_counts);
	
	
	var timer = get_tree().create_timer(origin_distance * 0.015)
	timer.timeout.connect(play_destroy)

func play_destroy():
	var tween = create_tween()
	tween.tween_method(on_tween, 0.0, 1.0, .45)
	tween.tween_callback(queue_free)

func on_tween(val):
	material.set_shader_parameter("progress", val)
	background_sprite.material.set_shader_parameter("progress", val)
