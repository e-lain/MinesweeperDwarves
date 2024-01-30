extends PanelContainer
class_name SpeechBubble

@onready var texture_rect = $TextureRect


func set_texture(texture):
	texture_rect.texture = texture
