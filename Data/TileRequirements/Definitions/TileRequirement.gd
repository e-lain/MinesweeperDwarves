class_name TileRequirement extends Resource

@export
var _problem: RequirementProblem = RequirementProblem.Other

enum RequirementProblem {
	Other,
	NoMinecart,
	NoLava
}

## "Virtual" function for testing if a tile requirement is met
func test(test_tile: BoardTile) -> bool:
	return false

func get_problem() -> RequirementProblem:
	return _problem
