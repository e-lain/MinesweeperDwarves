extends Control


@onready var image = $TextureRect
@onready var outline = $TextureRect2
@onready var label = $Label

var lifespan_seconds:= 1.0
@export var speed = 5.0

var start_time

func _ready():
	start_time = Time.get_ticks_msec()

func init(type: BuildingData.Type, lifespan: float, icon_path: String):
	lifespan_seconds = lifespan
	var data = BuildingData.data[type]
	var img = load(icon_path)
	image.texture = img
	outline.texture = img
	if data["stone_cost"] < 0:
		label.text = "+" + str(-data["stone_cost"])
	if data["steel_cost"] < 0:
		label.text = "+" + str(-data["steel_cost"])
	if data["population_cost"] < 0:
		label.text = "+" + str(-data["population_cost"])

func _process(delta):
	var t = (Time.get_ticks_msec() - start_time) / (lifespan_seconds * 1000.0)
	global_position.y -= delta * speed
	modulate.a = 1 - t
	
	if t >= 1:
		queue_free()
