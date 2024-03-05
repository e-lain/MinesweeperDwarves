class_name BuildingDataResource extends Resource

@export
var type: BuildingData.Type

@export
var name: String

@export
var description: String

@export
var model_script: Script = preload("res://Scripts/Entities/Model/BaseBuildingEntityModel.gd")

@export
var scene: PackedScene = preload("res://ViewScenes/BuildingEntityView.tscn")

@export
var _costs: Array[CostResource]

@export
var bounding_rect_dimensions: Vector2i

@export
var icon: Texture2D

@export
var orthogonal_tile_placement_requirements: Array[TileRequirement]

@export
var orthogonal_tile_collection_requirements: Array[TileRequirement]

var costs = {}

var _grants_resources: bool = false

func grants_resources() -> bool:
	return _grants_resources

func init():
	for cost in _costs:
		costs[cost.type] = cost.amount
		if cost.amount < 0:
			_grants_resources = true

func get_raw_costs() -> Array[CostResource]:
	return _costs
