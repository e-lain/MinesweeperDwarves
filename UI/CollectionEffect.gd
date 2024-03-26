class_name CollectionEffect extends Control


@onready var image = $HBoxContainer/TextureRect
@onready var outline = $HBoxContainer/TextureRect/TextureRect2
@onready var label =$HBoxContainer/Label

@export var speed = 5.0


func _ready():
	visible = false

func init(costs: Array[CostResource] = [], collection_count: int = 0):
	## TODO: support multiple cost types
	var cost: CostResource = costs[0]

	var icon_path: String = ResourceData.data[cost.type]["icon_path"]
	
	var img = load(icon_path)
	image.texture = img
	outline.texture = img
	label.text = "+" + str(-cost.amount)
	var lifespan = Globals.COLLECTION_EFFECT_LIFESPAN
	
	get_tree().create_timer(collection_count * 0.2).timeout.connect(func():
		visible = true
		var tween = get_tree().create_tween().bind_node(self).set_parallel(true)
		tween.tween_property(self, "position", position + Vector2(0, -speed * lifespan), lifespan).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(0, 0), lifespan).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.set_parallel(false)
		tween.tween_callback(queue_free))

