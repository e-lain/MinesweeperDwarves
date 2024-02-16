extends Node

# these are called via console.gd. Note that function params are passed as strings
var cheats = {
# TODO: fix this later
#	"tier": {
#		"func":
#			func tier(tier) -> void:
#				var main: GameController = get_tree().get_first_node_in_group("main")
#				tier = int(tier)
#				main.tier = tier
#				main.depth_by_tier[tier] = -1
#				main.available_buildings = []
#				if main.tier == 1:
#					main.total_workshop_count = 0
#				else:
#					main.total_workshop_count = 1
#				for i in tier + 1:
#					main.available_buildings.append_array(BiomeData.get_buildings(i))
#
#				main.next_level(),
#		"param_count": 1 # godot's callable doesnt have a way for us to determine this :(
#	},
	"giveme": {
		"func":
			func giveme(amount) -> void:
				amount = int(amount)
				for type in ResourceData.Resources.values():
					Resources.update_amount(type, amount),
		"param_count": 1
	},
	"solve": {
		"func":
			func solve() -> void:
				var main: GameController = get_tree().get_first_node_in_group("main")
				var board: Board = main.get_current_board()
				if (!board.bombs_initialized):
					board.set_bombs(Vector2i(0, 0))
				
				var bomb_tiles = board.bomb_tiles
				for col in board.tiles:
					for tile in col:
						if !tile.is_bomb && tile.is_cover:
							board.uncover_tile(tile)
						elif tile.is_bomb && !tile.is_flagged:
							board._on_flag_toggled(tile.cell_position)
				
				main.on_tile_uncover_event_complete(),
		"param_count": 0
	},
}

func _ready():
	if !PlatformUtil.is_debug_build():
		queue_free()
