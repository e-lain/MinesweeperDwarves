class_name EntityIdController extends RefCounted
## A simple Singleton which is responsible for generating entity IDs and keeping track of them.
static var INSTANCE: EntityIdController
var _last_id_generated: int

func _init(last_id_generated: int = 0) -> void:
	if INSTANCE == null:
		INSTANCE = self
	else:
		push_error("Attempted to construct multiple EntityIdController")
		return
	
	_last_id_generated = last_id_generated

func generate_id() -> int:
	_last_id_generated += 1
	return _last_id_generated
