class_name LavaConnectionController extends RefCounted

static var INSTANCE: LavaConnectionController

var last_connection_graph_id_generated: int = -1
var connection_graphs: Dictionary = {}

func _init():
	if INSTANCE == null:
		INSTANCE = self

func get_connection_graph(id: int) -> ConnectionGraph:
	return connection_graphs[id]
	

func get_next_connection_graph_id() -> int:
	last_connection_graph_id_generated += 1
	return last_connection_graph_id_generated

## Add all source and connection buildings in b to a, and then delete b from the connection_graphs dict.
func _merge_connection_graphs(a: ConnectionGraph, b: ConnectionGraph) -> void:
	for entity_id in b.lava_source_entity_ids:
		var lava_source: LavaEntityModel = BoardTileController.INSTANCE.get_entity(entity_id)
		lava_source.set_new_connection_graph_id(b.id)
		a.lava_source_entity_ids.append(entity_id)
	
	for entity_id in b.lava_connection_building_entity_ids:
		var lava_connected_building: LavaConnectedBuildingEntityModel = BoardTileController.INSTANCE.get_entity(entity_id)
		lava_connected_building.set_new_connection_graph_id(b.id)
		a.lava_connection_building_entity_ids.append(entity_id)
		
	connection_graphs.erase(b.id)

func add_lava_connection_entity(entity: BoardEntityModel, is_source: bool) -> void:
	assert(is_lava_connection_entity(entity))
	# In this method, we often rely on duck typing which assumes that LavaEntityModel and LavaConnectedBuildingEntityModel 
	# have the same functions available for interfacing with lava connection graphs. The best we can do until godot has interfaces.
	var entity_id = entity.get_id()
	var orthogonal_tiles := BoardTileController.INSTANCE.get_orthogonal_tiles_for_array(entity.get_occupied_tiles())
	var orthogonal_connection_graph_ids: Array[int] = []
	
	for tile in orthogonal_tiles:
		if !tile.has_entity():
			continue
		
		var orthogonal_entity_id := tile.get_entity_id()
		var orthogonal_entity := BoardTileController.INSTANCE.get_entity(orthogonal_entity_id)
		if is_lava_connection_entity(orthogonal_entity):

			var connection_id: int = orthogonal_entity.get_connection_graph_id()
			if !orthogonal_connection_graph_ids.has(connection_id):
				orthogonal_connection_graph_ids.append(connection_id)
	
	var graph_count := orthogonal_connection_graph_ids.size()
	
	# No orthogonal graph means that this placement should start a new graph
	if graph_count == 0:
		var new_graph := ConnectionGraph.new()
		new_graph.id = get_next_connection_graph_id()
		new_graph.add_entity_id(entity_id, is_source)
		
		entity.set_new_connection_graph_id(new_graph.id)
	else:
		# Each orthogonal connection graph to the added one gets merged together now
		while graph_count >= 2:
			var graph_a = connection_graphs[orthogonal_connection_graph_ids[0]]
			var graph_b = connection_graphs[orthogonal_connection_graph_ids[1]]
			_merge_connection_graphs(graph_a, graph_b)
			orthogonal_connection_graph_ids.remove_at(1)
			graph_count -= 1
		
		var graph_id := orthogonal_connection_graph_ids[0]
		var connection_graph: ConnectionGraph = connection_graphs[graph_id]
		connection_graph.add_entity_id(entity_id, is_source)

func remove_lava_connection_entity(entity: BoardEntityModel, is_source: bool) -> void:
	assert(is_lava_connection_entity(entity))
	
	var visited: Array[Dictionary] = []
	var entity_id = entity.get_id()
	var orthogonal_tiles := BoardTileController.INSTANCE.get_orthogonal_tiles_for_array(entity.get_occupied_tiles())
	
	var orthogonal_lava: Array[BoardTile] = []
	## For each orthogonal lava tile:
	## - if an orthogonal tile has been visited already by another BFS iteration, then that means that another orhtogonal direction still connects with the current tile. So skip running BFS again
	## - Otherwise, Perform BFS, marking visited tiles. Also skip the tile associated with entity given to this function, as it will be deleted.
	## In the end, each independent dictionary in the visited array is its own connection graph.
	## Delete the original graph, create new graphs for each, and update each entity with its new id.
	
	for tile in orthogonal_tiles:
		if !tile.has_entity():
			continue
		
		var orthogonal_entity_id := tile.get_entity_id()
		var orthogonal_entity := BoardTileController.INSTANCE.get_entity(orthogonal_entity_id)
		if !is_lava_connection_entity(orthogonal_entity):
			continue
		
		var cell_pos := tile.cell_position
		var skip = false
		# Checking to see if this tile has alerady been visited by a previous iteration of BFS.
		# If it has, then we will skip it, as it's already been included in another set
		for set in visited:
			if set.has(cell_pos):

				skip = true
				break
		
		if skip:
			continue
		
		
		# This is BFS, modified slightly because buildings can take up more than a 1x1 space (theoretically, at least)
		var cur_visited := {}
		var queue: Array[BoardTile] = []
		cur_visited[cell_pos] = true
		queue.push_back(tile)
		
		while !queue.is_empty():
			var current_tile: BoardTile = queue.pop_front()
			var current_entity_id := current_tile.get_entity_id()
			var current_entity := BoardTileController.INSTANCE.get_entity(current_entity_id)
			var current_occupied := current_entity.get_occupied_tiles()
			
			var current_ortho_tiles := BoardTileController.INSTANCE.get_orthogonal_tiles_for_array(current_occupied)
			for current_ortho_tile in current_ortho_tiles:
				if cur_visited.has(current_ortho_tile.cell_position):
					continue
					
				if !current_ortho_tile.has_entity():
					continue
				
				var current_ortho_tile_entity_id := current_ortho_tile.get_entity_id()
				var current_ortho_tile_entity := BoardTileController.INSTANCE.get_entity(current_ortho_tile_entity_id)
				if !is_lava_connection_entity(current_ortho_tile_entity):
					continue
					
				var cur_ortho_occupied_tiles := current_ortho_tile_entity.get_occupied_tiles()
				
				## Support for hypothoetical x2 lava connection building. In practice for now, this only loops once.
				for occupied in cur_ortho_occupied_tiles:
					cur_visited[occupied.cell_position] = true
				
				queue.push_back(current_ortho_tile)
		
		visited.append(cur_visited)
	
	connection_graphs.erase(entity.get_connection_graph_id())
	entity.set_new_connection_graph_id(-1)
	
	## Now each entry in visited is its own connection graph, build these and insert them into the connection graphs dict.
	for set in visited:
		var graph = ConnectionGraph.new()
		graph.id = get_next_connection_graph_id()
		var entity_ids := {}
		for cell_pos in set:
			var tile := BoardTileController.INSTANCE.get_tile_at_cell_position(cell_pos)
			var tile_entity_id := tile.get_entity_id()
			if entity_ids.has(tile_entity_id):
				continue
			entity_ids[tile_entity_id] = true
			var tile_entity := BoardTileController.INSTANCE.get_entity(tile_entity_id)
			tile_entity.set_new_connection_graph_id(graph.id)
			
			graph.add_entity_id(tile_entity_id, tile_entity is LavaEntityModel)
		
		connection_graphs[graph.id] = graph

func is_lava_connection_entity(entity: BoardEntityModel) -> bool:
	return entity is LavaEntityModel || entity is LavaConnectedBuildingEntityModel

class ConnectionGraph: 
	var id: int
	var lava_source_entity_ids: Array[int] = []
	var lava_connection_building_entity_ids: Array[int] = []
	
	func add_entity_id(entity_id: int, is_source: bool) -> void:
		if is_source: 
			lava_source_entity_ids.append(entity_id)
		else:
			lava_connection_building_entity_ids.append(entity_id) 
