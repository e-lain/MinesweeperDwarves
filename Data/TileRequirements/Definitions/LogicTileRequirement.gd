class_name LogicTileRequirement extends TileRequirement

enum Operation {
	AND,
	OR,
	NOT
}

@export
var operation: Operation

@export
var a: TileRequirement
@export
var b: TileRequirement

## "Virtual" function for testing if a tile requirement is met
func test(test_tile: BoardTile):
	match operation:
		Operation.AND:
			return a.test(test_tile) && b.test(test_tile)
		Operation.OR:
			return a.test(test_tile) || b.test(test_tile)
		Operation.NOT:
			return !a.test(test_tile)

