extends Control


@onready var image = $HBoxContainer/TextureRect
@onready var outline = $HBoxContainer/TextureRect/TextureRect2
@onready var label =$HBoxContainer/Label

var lifespan_seconds:= 1.0
@export var speed = 5.0

var start_time


func _ready():
	start_time = Time.get_ticks_msec()

func init(amount: int, lifespan: float, icon_path: String):
	lifespan_seconds = lifespan	
	
	
	var img = load(icon_path)
	image.texture = img
	outline.texture = img
	label.text = "+"+str(amount)
	
	
	var tween = get_tree().create_tween().bind_node(self).set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, -speed * lifespan_seconds), lifespan).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0, 0), lifespan).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)


#func _process(delta):
#	var t = (Time.get_ticks_msec() - start_time) / (lifespan_seconds * 1000.0)
#	global_position.y -= delta * speed
#	modulate.a = 1 - t
#
#	if t >= 1:
#		queue_free()
