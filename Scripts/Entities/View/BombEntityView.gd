class_name BombEntityView extends BoardEntityView

@onready var animation_player = $AnimationPlayer

signal animation_complete

func init(model: BoardEntityModel):
	super(model)
	var type: BombData.Type = (_model as BombEntityModel).get_bomb_type()
	sprite.texture = BombData.get_bomb_data(type).texture

func play_explode_animation():
	animation_player.play("explode")
	
func finish():
	animation_complete.emit()
