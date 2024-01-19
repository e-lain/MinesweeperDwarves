extends HBoxContainer
class_name ResourceBar

var resource_prefab = preload("res://UI/ResourceBarResource.tscn")

func update_available_resources(available_resources: Array[ResourceData.Resources]) -> void:
	for child in get_children():
		child.queue_free()
	
	for resource in available_resources:
		var instance = resource_prefab.instantiate()
		add_child(instance)
		instance.set_data(resource, 0)
		
func set_resource_count(type: ResourceData.Resources, val: int):
	for child in get_children():
		if child.type == type:
			child.update_amount(val)
