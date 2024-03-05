class_name LavaSourceEntityView extends BombEntityView

@onready var pointlight: PointLight2D = $PointLight2D

func init(model: BoardEntityModel):
	super(model)

	pointlight.visible = true
