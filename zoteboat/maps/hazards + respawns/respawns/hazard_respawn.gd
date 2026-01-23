extends Node2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player") || Global.map_holder.is_transition:
		return
	
	
	
	body.set_hazard_respawn()
