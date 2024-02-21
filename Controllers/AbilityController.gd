extends Node
class_name AbilityController

@onready var board = get_parent()
@onready var main = get_parent().get_parent()

# Preload ability scenes that need to be
var Destroy = preload("res://Abilities/Destroy.tscn")

func activate_ability(ability_type: AbilityData.Type):
	match (ability_type):
		AbilityData.Type.DOWSE:
			ability_dowse()
			return
		AbilityData.Type.DESTROY:
			ability_destroy()
			return
		AbilityData.Type.ARMOR:
			ability_armor()
			return
	return 
	
func ability_dowse():
	print("SIGNAL RECEIVED TO USE DOWSE ABILITY")
	main.use_ability_charge(AbilityData.Type.DOWSE)
	board.complete_ability()
	if board.bomb_tiles.size() > 0:
		var picked = false
		while !picked:
			print("bomb tiles: ", board.bomb_tiles)
			var rand_index:int = randi() % board.bomb_tiles.size()
			if !board.bomb_tiles[rand_index].is_flagged:
				board.bomb_tiles[rand_index].toggle_flag()
				board.bombs_found += 1
				print("bombs found: ", board.bombs_found)
				board.flags -= 1
				picked = true
				return
	return
	
func ability_destroy():
	print("SIGNAL RECEIVED TO USE DESTROY ABILITY")
	var ability = Destroy.instantiate()
	board.clearing_tile = true
	board.add_child(ability)
	
func ability_armor():
	print("SIGNAL RECEIVED TO USE ARMOR ABILITY")
	board.complete_ability()
	board.armor_active = true
	return
