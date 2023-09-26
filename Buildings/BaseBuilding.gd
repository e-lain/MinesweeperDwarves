extends Node2D
class_name BaseBuilding

@export var type: BuildingData.Type
@onready var sprite: Sprite2D = $Sprite2D
@onready var no_minecart_sprite: Sprite2D = $NoMinecart

@onready var background_sprite: Sprite2D = $BG

var building_placement_material: ShaderMaterial = preload("res://Shaders/InvalidBuildingPlacement.tres")


const bg_offset := Vector2i(3, 3)


const collection_prefab: PackedScene = preload("res://UI/collection_effect.tscn")

const TILE_SIZE = 64

var placed: bool = false
var in_bounds: bool = false

var id: int
var size: int

var took_help_text_override = false

func set_type(value, icon):
	type = value
	size = BuildingData.data[type]["size"]
	sprite.texture = icon

func _process(delta):
	if !placed:
		var mouse = get_parent().get_local_mouse_position()
		var snapped = Vector2(snapped(mouse.x-TILE_SIZE/2, TILE_SIZE), snapped(mouse.y-TILE_SIZE/2, TILE_SIZE))
		position = snapped
		if position.x <= 0 - TILE_SIZE || position.x >= TILE_SIZE * get_parent().rows || position.y <= 0-TILE_SIZE || position.y >= TILE_SIZE * get_parent().columns:
			self.hide()
			in_bounds = false
		else:
			self.show()
			in_bounds = true
		if in_bounds:
			if !can_place():
				sprite.material = building_placement_material
			else:
				sprite.material = null
		
		if size == 1:
			background_sprite.visible = false
		else:
			background_sprite.position = bg_offset
			var cell_pos = get_parent().world_to_cell(global_position)
			var region_x = bg_offset.x if cell_pos.x % 2 == 0 else 64 + bg_offset.x
			var region_y = bg_offset.y if cell_pos.y % 2 == 0 else 64 + bg_offset.y
			var region_w = size * TILE_SIZE - bg_offset.x * 2
			var region_h = size * TILE_SIZE - bg_offset.y * 2
			background_sprite.region_rect = Rect2(region_x, region_y, region_w, region_h)
	
	if placed && (type == BuildingData.Type.HOUSE || type == BuildingData.Type.QUARRY):
		var next_to_minecart = next_to_minecart()
		no_minecart_sprite.visible = !next_to_minecart
		sprite.modulate.a = 1 if next_to_minecart else 0.7 
		
		var mouse_pos = get_local_mouse_position()
		var mouse_in_bounds = mouse_pos.x >= 0 && mouse_pos.y >= 0 && mouse_pos.x < TILE_SIZE * size && mouse_pos.y < TILE_SIZE * size
		if !next_to_minecart && !get_parent().get_parent().help_text_is_overriden && mouse_in_bounds:
			get_parent().get_parent().help_text_bar.text = "Building will not earn resources when you descend to next floor. Build a minecart next to this building."
			get_parent().get_parent().help_text_is_overriden = true
			took_help_text_override = true
		elif took_help_text_override && !mouse_in_bounds:
			get_parent().get_parent().help_text_is_overriden = false
			took_help_text_override = false

func can_place():
	return get_parent().can_place_at_position(global_position, size)

func next_to_minecart() -> bool:
	return get_parent().building_is_next_to_minecart(self) || get_parent().player_placing_minecart_next_to_building(self)


func _on_control_gui_input(event):
	if event is InputEventMouseButton && !placed:
		if event.is_action_pressed("left_click"):
			if !can_place():
				SoundManager.play_negative()
			if type == BuildingData.Type.STAIRCASE and get_parent().stairs_placed:
				get_parent().get_parent().help_text_bar.text = "Stairs already placed! Can't have more than one staircase per floor"
				print("Stairs already placed!")
			if can_place() && in_bounds:
				placed = true
				get_parent().on_building_placed(global_position, self)

				sprite.material = null
				return
		if event.is_action_pressed("right_click"):
			get_parent().placing = false
			get_parent().get_parent().help_text_is_overriden = false
			queue_free()

func play_collection_animation(lifespan_seconds: float, icon_path: String):
	var instance = collection_prefab.instantiate()
	add_child(instance)
	var amount = 0
	var data = BuildingData.data[type]
	if data["stone_cost"] < 0:
		amount = -data["stone_cost"]
	if data["steel_cost"] < 0:
		amount = -data["steel_cost"]
	if data["population_cost"] < 0:
		amount = -data["population_cost"]
	
	instance.init(amount, lifespan_seconds, icon_path)
	instance.global_position = global_position + (Vector2(TILE_SIZE, TILE_SIZE) * size / 2.0) + Vector2(0, -16)
