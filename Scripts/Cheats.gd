extends Node

# these are called via console.gd. Note that function params are passed as strings
var cheats = {
	"tier": {
		"func":
			func tier(tier) -> void:
				var main = get_tree().get_first_node_in_group("main")
				main.override_tier(int(tier)),
		"param_count": 1 # godot's callable doesnt have a way for us to determine this :(
	},
	"giveme": {
		"func":
			func giveme(amount) -> void:
				amount = int(amount)
				Resources.steel += amount
				Resources.stone += amount
				Resources.population += amount
				Resources.sledgehammer += amount,
		"param_count": 1 # godot's callable doesnt have a way for us to determine this :(
	}
}

func _ready():
	if !PlatformUtil.is_debug_build():
		queue_free()
