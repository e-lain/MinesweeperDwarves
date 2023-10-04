class_name AbilityData

enum Type {
	DOWSE,
	DESTROY,
	ARMOR
}

static var Data = {
	Type.DOWSE: {
		"type": Type.DOWSE,
		"name": "Dowsing Rod",
		"description": "Flag a random bomb",
		"icon_path": "res://Assets/UI/dowsingrodicon.png",
		"small_icon_path": "res://Assets/UI/DowsingRodDownscaled.png"
	},
	Type.DESTROY: {
		"type": Type.DESTROY,
		"name": "Crane",
		"description": "Safely remove selected tile",
		"icon_path": "res://Assets/UI/CraneUI.png",
		"small_icon_path": "res://Assets/UI/CraneSmaller.png"		
	},
	Type.ARMOR: {
		"type": Type.ARMOR,
		"name": "Active Armor",
		"description": "Take no damage when revealing the next tile",
		"icon_path": "res://Assets/UI/dowsingrodicon.png",
		"small_icon_path": "res://Assets/UI/DowsingRodDownscaled.png"		
	}
}
