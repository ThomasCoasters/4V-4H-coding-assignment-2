extends Node2D

@export var damage: int = 1


func _on_static_body_2d_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player") || body.is_in_group("invincible") || Global.map_holder.is_transition:
		return
	
	
	body.on_spikes_entered(damage)
