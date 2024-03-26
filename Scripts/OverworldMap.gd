class_name OverworldMap extends Node

# This will do for now, in the future, consider Wave Function Collapse: https://robertheaton.com/2018/12/17/wavefunction-collapse-algorithm/
# OR let players place the location + size of minesweep area themselves

@export var max_size: Vector2i = Vector2i(300, 300)
@export var start_room_size: int = 6
@export var min_room_size = 6
@export var max_room_size = 18
@onready var room_tile_prefab = preload("res://Prefabs/OverworldTestTilePrefab.tscn")


var rooms_visited = 1

var grid = []
var last_generated_room_id = -1
var rooms = {}


class Room:
	var id: int
	var size: Vector2i
	var origin: Vector2i
	var sprite: Sprite2D
	var origin_room_id: int
	var visited: bool
	var board: Board
	
	func visit():
		visited = true
		if sprite != null:
			sprite.modulate.a = 1.0
	

func _ready():
	for i in max_size.x:
		var col = []
		for j in max_size.y:
			col.append(-1)
		grid.append(col)


func generate_room(size: int, origin: Vector2i, origin_room_id: int = -1) -> int:
	last_generated_room_id += 1 
	
	for x in size:
		for y in size:
			grid[origin.x + x][origin.y + y] = last_generated_room_id
	
	var room = Room.new()
	room.id = last_generated_room_id
	room.size = Vector2i(size, size)
	room.origin = origin
	room.origin_room_id = origin_room_id
	rooms[room.id] = room
	
	return room.id

func generate_choices(origin_room_id: int, target_size: int) -> Array[int]:
	# This function takes an origin room and tries to fill in rooms adjacent to the origin room. 
	# It does this very naively:
	#   1. Iteratively check in a square area on each adjacent side. Each loop bumps the check origin over a bit or shrinks the search area. This generates the set of all possible placement options on each side
	#   2. Determine if there are adjacent sides which need to be checked against eachother for simultaneous placement collisions
	#   3. Perform checks on all combinations of adjacent sides to ensure our options are limited to the valid, non-colliding set.
	#   4. Once all valid combinations have been found, try to pick a random combination from the subset which has the greatest variety of room size options.
	# Improvements: wave function collapse algorithm or a dynamic programming approach would likely be much faster. \
	# But keeping the max_offset variable low means we don't generate too many combinations and it still finishes real quick. 
	
	var sizes = []
	var origin_room = rooms[origin_room_id]
	
	var lower_bound = max(min_room_size, target_size - 1)
	for i in range(lower_bound, min(max_room_size, lower_bound + 3)):
		sizes.append(i)
	
	var largest_size = sizes[sizes.size() - 1]
	
	sizes.reverse()
	
	
	# Uncomment for more variety, but also a longer algorithm runtime
	var max_offset = 2 #smallest_size / 2
	var offset_variant_count = 2 * max_offset + 1
	
	
	# check sides in all 4 directions for room placement options:
	# We _know_ that at least one will have placementoptions
	var original_room_test_origins = [
		{"side": Vector2i.LEFT, "origin": origin_room.origin + Vector2i(-largest_size, -max_offset), "offset_direction": Vector2i.RIGHT, "origin_shift": Vector2i.DOWN},
	 	{"side": Vector2i.UP, "origin": origin_room.origin + Vector2i(-max_offset, -largest_size), "offset_direction": Vector2i.DOWN, "origin_shift": Vector2i.RIGHT},
		{"side": Vector2i.RIGHT, "origin": origin_room.origin + Vector2i(origin_room.size.x, -max_offset), "offset_direction": Vector2i.ZERO, "origin_shift": Vector2i.DOWN},
		{"side": Vector2i.DOWN, "origin": origin_room.origin + Vector2i(-max_offset, origin_room.size.y), "offset_direction": Vector2i.ZERO, "origin_shift": Vector2i.RIGHT}
	] 
	
	var options = {Vector2i.LEFT: {}, Vector2i.UP: {}, Vector2i.RIGHT: {}, Vector2i.DOWN: {}}
	
	for test in original_room_test_origins:
		var side = test["side"]
		var origin = test["origin"]
		var offset_dir = test["offset_direction"]
		var origin_shift = test["origin_shift"]
		
	
		for size in sizes:
			var test_origin = origin
			for i in range(origin_room.size.x - size + offset_variant_count):
				# todo: even faster shorcut for expensive would_fit check? (dynamic programming feels appropriate here)
				if would_fit(test_origin, Vector2i(size, size)):
					if !options[side].has(size):
						options[side][size] = []
					
					options[side][size].append(test_origin)
				
				test_origin += origin_shift
			origin += offset_dir
		
	# at least one of options dict should be empty
	# naive approach: pick every combination of option in options with 3 different sizes and choose the compatible ones with a room choice at each desired size
	# this is uh, pretty bad but it should work
	var non_empty_found: bool = false
	var best_test_side = null
	var best_test_side_index = -1
	var max_adjacent = 0
	
	var sides = [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]
	
	
	for i in range(len(sides)):
		var side = sides[i]
	
		if options[side].is_empty():
			continue
			
		non_empty_found = true
			
		if max_adjacent == 0:
			best_test_side = side
			best_test_side_index = i
		
		var counter_clockwise = sides[i - 1 if i > 0 else 3]
		var clockwise = sides[i + 1 if i < 3 else 0]
		
		var adjacent_count = 0
		
		if !options[clockwise].is_empty():
			adjacent_count += 1
		if !options[counter_clockwise].is_empty():
			adjacent_count += 1
			
		if max_adjacent < adjacent_count:
			max_adjacent = adjacent_count
			best_test_side = side
			best_test_side_index = i
	
	# no sides have any possible placements, give up!
	if !non_empty_found:
		return []
	
	var possible_combinations = {}
	var clockwise = null
	var counter_clockwise = null
	
	if max_adjacent > 0:
		counter_clockwise = sides[best_test_side_index - 1 if best_test_side_index > 0 else 3]
		clockwise = sides[best_test_side_index + 1 if best_test_side_index < 3 else 0]
	else:
		
		# Hack to handle opposite sides with valid placements or a single side with valid placement
		for option_side in sides:
			if options[option_side].is_empty() || (option_side.x == best_test_side.x && option_side.y == best_test_side.y):
				continue
			
			clockwise = option_side

	
	var can_fill_clockwise = clockwise != null && !options[clockwise].is_empty()
	var can_fill_counter_clockwise = counter_clockwise != null && !options[counter_clockwise].is_empty()


	for test_size in options[best_test_side].keys():
		var test_dimension = Vector2i(test_size, test_size)
		for origin in options[best_test_side][test_size]:
			var compatible_clockwise_placements = []
			if can_fill_clockwise:
				for clockwise_test_size in options[clockwise].keys():
					for clockwise_origin in options[clockwise][clockwise_test_size]:
						if !would_rooms_collide(origin, test_dimension, clockwise_origin, Vector2i(clockwise_test_size, clockwise_test_size)):
							compatible_clockwise_placements.append({"origin": clockwise_origin, "size": clockwise_test_size})
				
				# if clockwise spot would otherwise be able to place rooms, but our current origin + test_size would prevent room placement, skip to next test point
				if compatible_clockwise_placements.is_empty():
					continue
			
			var compatible_counter_clockwise_placements = []
			if can_fill_counter_clockwise:
				for counter_clockwise_test_size in options[counter_clockwise].keys():
					for counter_clockwise_origin in options[counter_clockwise][counter_clockwise_test_size]:
						if !would_rooms_collide(origin, test_dimension, counter_clockwise_origin, Vector2i(counter_clockwise_test_size, counter_clockwise_test_size)):
							compatible_counter_clockwise_placements.append({"origin": counter_clockwise_origin, "size": counter_clockwise_test_size})
				
				if compatible_counter_clockwise_placements.is_empty():
					continue
			
			
			if !can_fill_clockwise && !can_fill_counter_clockwise:
				var combination_entry = {}
				combination_entry[test_size] = [origin]
				
				if !possible_combinations.has(1):
					possible_combinations[1] = []
				
				possible_combinations[1].append(combination_entry)
			elif can_fill_clockwise && can_fill_counter_clockwise:
				for clockwise_placement in compatible_clockwise_placements:
					for counter_clockwise_placement in compatible_counter_clockwise_placements:
						var combination_entry = {}
						combination_entry[test_size] = [origin]
						
						if !combination_entry.has(counter_clockwise_placement["size"]):
							combination_entry[counter_clockwise_placement["size"]] = []
						
						combination_entry[counter_clockwise_placement["size"]].append(counter_clockwise_placement["origin"])
						
						if !combination_entry.has(clockwise_placement["size"]):
							combination_entry[clockwise_placement["size"]] = []
						
						combination_entry[clockwise_placement["size"]].append(clockwise_placement["origin"])
					
						if !possible_combinations.has(combination_entry.size()):
							possible_combinations[combination_entry.size()] = []
				
						possible_combinations[combination_entry.size()].append(combination_entry)
			elif can_fill_clockwise:
				for clockwise_placement in compatible_clockwise_placements:
						var combination_entry = {}
						combination_entry[test_size] = [origin]
					
						if !combination_entry.has(clockwise_placement["size"]):
							combination_entry[clockwise_placement["size"]] = []
						
						combination_entry[clockwise_placement["size"]].append(clockwise_placement["origin"])
					
						if !possible_combinations.has(combination_entry.size()):
							possible_combinations[combination_entry.size()] = []
				
						possible_combinations[combination_entry.size()].append(combination_entry)
			else:
				for counter_clockwise_placement in compatible_counter_clockwise_placements:
					var combination_entry = {}
					combination_entry[test_size] = [origin]
					
					if !combination_entry.has(counter_clockwise_placement["size"]):
						combination_entry[counter_clockwise_placement["size"]] = []
					
					combination_entry[counter_clockwise_placement["size"]].append(counter_clockwise_placement["origin"])
				
					if !possible_combinations.has(combination_entry.size()):
						possible_combinations[combination_entry.size()] = []
			
					possible_combinations[combination_entry.size()].append(combination_entry)
	
	for i in range(3, 0, -1):
		if !possible_combinations.has(i):
			continue
		
		var index = randi_range(0, possible_combinations[i].size() -1)
		var combination = possible_combinations[i][index]
	
		var result: Array[int] = []
		
		for size in combination.keys():
			for origin in combination[size]:
				result.append(generate_room(size, origin, origin_room_id))
		
		return result
	
	return []


func would_rooms_collide(r1_origin: Vector2i, r1_dimension: Vector2i, r2_origin: Vector2i, r2_dimension: Vector2i):
	return r1_origin.x < r2_origin.x + r2_dimension.x && \
	r1_origin.x + r1_dimension.x > r2_origin.x && \
	r1_origin.y < r2_origin.y + r2_dimension.y && \
	r1_origin.y + r1_dimension.y > r2_origin.y


func would_fit(room_origin: Vector2i, room_dimensions: Vector2i):
	if room_origin.x < 0 || room_origin.y < 0 || room_origin.x + room_dimensions.x >= max_size.x || room_origin.y + room_dimensions.y >= max_size.y:
		return false
	
	for x in range(room_origin.x, room_origin.x + room_dimensions.x):
		for y in range(room_origin.y, room_origin.y + room_dimensions.y):
			if grid[x][y] >= 0:
				return false
	
	return true

func _on_room_choice_made(_viewport, event: InputEvent, _shape_id, room_id: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and !rooms[room_id].visited:
		rooms[room_id].visit()
	
		var origin_room = rooms[room_id]
		# Interpolate our desired room size from map center to map boundaries. TODO: consider how an infinite map might affect this
		var t = Vector2(origin_room.origin).distance_to(Vector2(rooms[0].origin)) / Vector2(max_size / 2.0).length()
		var target_size = roundi((lerp(min_room_size, max_room_size, t)))
			
		generate_choices(room_id, target_size)
	

func assign_board(room_id: int, board: Board):
	rooms[room_id].board = board
	rooms[room_id].visit()
	board.overworld_room_id = room_id
	
