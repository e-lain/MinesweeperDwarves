class_name BoardTile

var number_label_prefab: PackedScene = preload("res://Prefabs/NumberLabel.tscn")
var flag_prefab: PackedScene = preload("res://Prefabs/Flag.tscn")
var bomb_prefab: PackedScene = preload("res://Prefabs/Bomb.tscn")

const TILE_SIZE = 64

var cell_position: Vector2i

var is_cover: bool = true
var is_flagged: bool = false

var is_bomb: bool = false
var bomb_type: BombData.Type

var has_building: bool = false
var building_id: int
# Only used if bomb is a lava source
var lava_uid: int

var label
var flag
var bomb

var label_parent

func set_bomb(bomb_type: BombData.Type):
	is_bomb = true
	self.bomb_type = bomb_type

func toggle_flag():
	if is_cover:
		if !is_flagged:
			is_flagged = true
			create_flag()
		elif is_flagged:
			is_flagged = false
			destroy_flag()

func create_label(adjacent_bomb_count: int):
	if label != null:
		label.queue_free()
		label = null
	
	if adjacent_bomb_count > 0:
		label = number_label_prefab.instantiate()
		label_parent.add_child(label)
		label.position = get_position()
		label.set_number(adjacent_bomb_count)

func create_flag():
	flag = flag_prefab.instantiate()
	label_parent.add_child(flag)
	flag.position = get_position()

func destroy_flag():
	if flag != null:
		flag.queue_free()
		flag = null

func create_bomb(bomb_type: BombData.Type) -> Node2D:
	bomb = bomb_prefab.instantiate()
	bomb.set_type(bomb_type)
	label_parent.add_child(bomb)
	bomb.position = get_position()
	return bomb

func get_position():
	return cell_position * TILE_SIZE + Vector2i(TILE_SIZE / 2, TILE_SIZE / 2)

func destroy_bomb():
	if bomb != null:
		is_bomb = false
		bomb.queue_free()
		bomb = null
