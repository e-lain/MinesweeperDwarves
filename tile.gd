extends Node2D

const TILE_SIZE = 32

var is_cover: bool = true
var is_flagged: bool = false
var is_bomb: bool = false

func set_bomb():
	is_bomb = true
	$Bomb.show()
	$Label.hide()

func uncover():
	if !is_flagged:
		is_cover = false
		$Cover.hide()
	var count_surroundings = 0
	for tile in get_surroundings():
		if tile.is_bomb:
			count_surroundings += 1
	if count_surroundings > 0:
		$Label.text = str(count_surroundings)
	else:
		for tile in get_surroundings():
			if tile.is_cover && !is_bomb:
				tile.uncover()
		
func get_surroundings():
	var surroundings = []
	var offsets = [
		(Vector2.UP + Vector2.LEFT) * TILE_SIZE,
		(Vector2.UP) * TILE_SIZE,
		(Vector2.UP + Vector2.RIGHT) * TILE_SIZE,
		(Vector2.LEFT) * TILE_SIZE,
		(Vector2.RIGHT) * TILE_SIZE,
		(Vector2.DOWN + Vector2.LEFT) * TILE_SIZE,
		(Vector2.DOWN) * TILE_SIZE,
		(Vector2.DOWN + Vector2.RIGHT) * TILE_SIZE,
	]
	for offset in offsets:
		for tile in get_parent().tiles:
			if tile.position == position + offset:
				surroundings.append(tile)
	return surroundings
	
func toggle_flag():
	if is_cover:
		if !is_flagged:
			is_flagged = true
			$Flag.show()
		elif is_flagged:
			is_flagged = false
			$Flag.hide()

func _on_control_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click"):
			uncover()
		if event.is_action_pressed("right_click"):
			toggle_flag()
