class_name BombData

enum Type {
	DEFAULT,
	LAVA
}

static var data = {
	Type.DEFAULT: {
		"type": Type.DEFAULT,
		"name": "Bomb",
		"resource": ResourceData.Resources.STEEL,
		"texture": "res://Assets/Mine.png"
	},
	Type.LAVA: {
		"type": Type.LAVA,
		"name": "Lava",
		"texture": "res://Assets/walltiles/LavaBlock.png" # TODO: Replace with legit texture once available
	}
}
