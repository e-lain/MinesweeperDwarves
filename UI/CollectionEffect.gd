extends Control


@onready var image = $HBoxContainer/TextureRect
@onready var outline = $HBoxContainer/TextureRect/TextureRect2
@onready var label =$HBoxContainer/Label

@export var speed = 5.0


func _ready():
	visible = false

func init(amount: int, icon_path: String, collection_count: int = 0):
	var img = load(icon_path)
	image.texture = img
	outline.texture = img
	label.text = "+"+str(amount)
	var lifespan = Globals.collection_effect_lifespan
	
	get_tree().create_timer(collection_count * 0.2).timeout.connect(func():
		visible = true
		var tween = get_tree().create_tween().bind_node(self).set_parallel(true)
		tween.tween_property(self, "position", position + Vector2(0, -speed * lifespan), lifespan).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(0, 0), lifespan).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.set_parallel(false)
		tween.tween_callback(queue_free))

