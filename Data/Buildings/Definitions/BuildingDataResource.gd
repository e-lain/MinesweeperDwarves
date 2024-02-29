class_name BuildingDataResource extends Resource

@export
var type: BuildingData.Type

@export
var name: String
@export
var description: String


## For instantiating the correct building entity model for the associated building.
## Unfortunately, it isn't possible to limit script export to certain kinds of scripts
@export
var building_entity_model_script: Script = preload("res://Scripts/Entities/Model/BaseBuildingEntityModel.gd")

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

func _init():
	super()
	for cost in _costs:
		costs[cost.type] = cost.amount
