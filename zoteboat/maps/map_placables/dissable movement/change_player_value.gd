extends Area2D

@export var changed_stuff: Array[KeyValue] = []


func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player") || Global.map_holder.is_transition:
		return
	
	for kv in changed_stuff:
		body.set(kv.key, kv.value)
