class_name LavaMoatEntityView extends BuildingEntityView

@onready var pointlight: PointLight2D = $PointLight2D

func init(model: BoardEntityModel):
	super(model)

	pointlight.visible = true
