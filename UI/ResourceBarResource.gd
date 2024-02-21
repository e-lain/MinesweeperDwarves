extends HBoxContainer


@onready var texture_rect = $TextureRect
@onready var label = $Label

var type: ResourceData.Resources

var target_amt: int
var current_amt_displayed: int
var anim_speed: float = 20

var current_tween: Tween

func set_data(type: ResourceData.Resources, amount: int):
	self.type = type
	texture_rect.texture = load(ResourceData.data[type]["icon_path"])
	label.text = str(amount)
	target_amt = amount
	current_amt_displayed = amount


func update_amount(amt: int):
	if (current_tween != null && current_tween.is_valid()):
		current_tween.kill()
	
	target_amt = amt

	var tween_duration = min(float(abs(target_amt - current_amt_displayed)) / anim_speed, 0.7)
	
	current_tween = get_tree().create_tween().bind_node(self)
	current_tween.tween_method(func(val):
		current_amt_displayed = val
		label.text = str(val), 
		current_amt_displayed, target_amt, tween_duration)
	
	texture_rect.pivot_offset = Vector2(32, 32)
	var icon_tween = get_tree().create_tween().bind_node(self)
	icon_tween.tween_property(texture_rect, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	icon_tween.tween_property(texture_rect, "scale", Vector2(1, 1), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

