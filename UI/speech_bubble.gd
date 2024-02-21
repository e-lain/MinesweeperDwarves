extends PanelContainer
class_name SpeechBubble

@onready var texture_rect = $TextureRect

var revealed: bool = false
var current_tween: Tween

func _ready():
	size = Globals.TILE_SIZE_VECTOR
	pivot_offset = Vector2(Globals.TILE_SIZE / 2, Globals.TILE_SIZE)
	scale = Vector2(0,0)
	visible = false

func set_revealed(val: bool, tween_time: float = 0.5) -> void:
	if revealed != val:
		revealed = val
		if current_tween != null && current_tween.is_valid():
			current_tween.kill()
		
		if revealed:
			visible = true
		
		current_tween = get_tree().create_tween().bind_node(self)
		var prop_tween = current_tween.tween_property(self, "scale", Vector2(1,1) if revealed else Vector2(0,0), tween_time)
		if !revealed:
			prop_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
			current_tween.tween_callback(func(): visible = false)
		else:
			prop_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		


func set_texture(texture) -> void:
	texture_rect.texture = texture
