extends Node2D

@export var grid_line_prefab: PackedScene = preload("res://ArtTest/GridLine.tscn")
@onready var tilemap: TileMap = $WallTileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in 30:
		var instance
		if i < 12:
			instance = grid_line_prefab.instantiate()
			add_child(instance)
			instance.global_position.y = 64 * i
			instance.material.set_shader_parameter("speed", randf_range(0.01, 0.03) * (-1.0 if i % 2 == 0 else 1.0))
			
		instance = grid_line_prefab.instantiate()
		add_child(instance)
		instance.global_rotation_degrees = 90
		instance.global_position.x = 64 * i
		instance.global_position.y = 360
		
		instance.material.set_shader_parameter("speed", randf_range(0.01, 0.03) * (-1.0 if i % 2 == 0 else 1.0))
	
	update_shadows()

func update_shadows():
	var used_cells = tilemap.get_used_cells(0)
	var occupied_tiles = {}
	
	var min_x = 9999999
	var max_x = -999999
	var min_y = 999999
	var max_y = -999999
	for pos in used_cells:
		if pos.x < min_x:
			min_x = int(pos.x)
		elif pos.x > max_x:
			max_x = int(pos.x)
		if pos.y < min_y:
			min_y = int(pos.y)
		elif pos.y > max_y:
			max_y = int(pos.y)
		
		occupied_tiles[pos] = null
	
	var unused_cells = []
	for x in range(min_x, max_x):
		for y in range(min_y, max_y):
			var cell = Vector2i(x,y)
			if !occupied_tiles.has(cell):
				unused_cells.append(cell)
	
	tilemap.clear_layer(1)
	tilemap.set_cells_terrain_connect(1, unused_cells, 0, 1)
