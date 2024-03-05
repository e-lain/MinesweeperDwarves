class_name LavaBuildingView extends BuildingEntityView

@onready var pointlight = $PointLight2D


func init(model: BoardEntityModel):
	super(model)

	pointlight.visible = true
