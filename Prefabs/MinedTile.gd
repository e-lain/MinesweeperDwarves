extends Sprite2D

@onready var background_sprite = $BG

func _ready():
	visible = false

func init(_position: Vector2, tilesheet_sprite_coords:Vector2i, cell_position: Vector2i, origin_distance: int = 0):
	visible = true
	position = _position
	
	
	
	frame_coords = tilesheet_sprite_coords
	
	var region_x = 0 if cell_position.x % 2 == 0 else 64
	var region_y = 0 if cell_position.y % 2 == 0 else 64
	var region_w = 64
	var region_h = 64
	background_sprite.region_rect = Rect2(region_x, region_y, region_w, region_h)
	
	var timer = get_tree().create_timer(origin_distance * 0.015)
	timer.timeout.connect(play_destroy)

func play_destroy():
	var tween = get_tree().create_tween().bind_node(self)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(queue_free)
