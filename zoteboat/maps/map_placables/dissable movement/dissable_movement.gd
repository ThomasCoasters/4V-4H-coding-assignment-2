extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player") || Global.map_holder.is_transition:
		return
	
	
	
	body.can_move = false
