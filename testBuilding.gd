extends Node2D

const TILE_SIZE = 64

var placed: bool = false
var in_bounds: bool = false
var num_collisions = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

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
		if num_collisions > 0:
			print("Place red shader here")
		else:
			print("Revert shader to normal here")

func _input(event):
	if event is InputEventMouseButton && !placed:
		if event.is_action_pressed("left_click"):
			if num_collisions == 0 && in_bounds:
				placed = true
				get_parent().placing = false
				return
		if event.is_action_pressed("right_click"):
			get_parent().placing = false
			queue_free()

func _on_area_2d_area_entered(area):
	num_collisions += 1

func _on_area_2d_area_exited(area):
	num_collisions -= 1
