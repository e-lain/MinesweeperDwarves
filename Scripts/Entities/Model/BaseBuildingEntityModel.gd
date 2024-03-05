class_name BaseBuildingEntityModel extends BoardEntityModel
## Base Model Class for Building Entities

# Resource which is shared by all buildings of this type.
var _building_data: BuildingDataResource : get = get_building_data

## Constructor
func _init(origin_pos: Vector2i, type: BuildingData.Type) -> void:
	_building_data = BuildingData.INSTANCE.get_building_data(type)
	## TODO: Replace this when Adding non-square/recangle support for buildings
	var bounding_rect := Rect2i(origin_pos, _building_data.bounding_rect_dimensions)

	super(bounding_rect)

## Would permanently placing the building at the current position be allowed?
func can_place() -> bool:
	if !super():
		return false

	var placement_requirements: Array[TileRequirement] = get_building_data().orthogonal_tile_placement_requirements
	
	return check_requirements(placement_requirements).size() == 0

func get_collection_problems() -> Array[TileRequirement.RequirementProblem]:
	var collection_requirements: Array[TileRequirement] = get_building_data().orthogonal_tile_collection_requirements
	return check_requirements(collection_requirements)

	## Check every tile to see if it fulfills the building's requirements.
	## If every requirements is fulfilled, return empty array. Otherwise, return an array containing each failed requirement
func check_requirements(requirements: Array[TileRequirement]) -> Array[TileRequirement.RequirementProblem]:
	var tiles := BoardTileController.INSTANCE.get_tiles_in_area(_bounding_cell_rect)
	var orthogonal_tiles  := BoardTileController.INSTANCE.get_orthogonal_tiles_for_array(tiles)
	
	var failed: Array[TileRequirement.RequirementProblem] = []
	for requirement in requirements:
		var passed = false
		for tile in orthogonal_tiles:
			if requirement.test(tile):
				passed = true
				break
		if !passed:
			failed.append(requirement.get_problem())
	
	return failed

func _pay_costs() -> void:
	var costs := _building_data.get_raw_costs()
	
	for cost in costs:
		if cost.amount > 0:
			Resources.update_amount(cost.type, -cost.amount)

func _refund_costs() -> void:
	var costs := _building_data.get_raw_costs()
	
	for cost in costs:
		if cost.amount > 0:
			Resources.update_amount(cost.type, cost.amount)

func collect() -> void:
	var costs := _building_data.get_raw_costs()
	
	for cost in costs:
		if cost.amount < 0:
			Resources.update_amount(cost.type, -cost.amount)


func place(bounding_cell_rect: Rect2i) -> void:
	super(bounding_cell_rect)
	_pay_costs()

func unplace() -> void:
	if _is_placed:
		_refund_costs()
	super()


func remove() -> void:
	super()

func get_type() -> BuildingData.Type:
	return _building_data.type

func get_building_data() -> BuildingDataResource:
	return _building_data
