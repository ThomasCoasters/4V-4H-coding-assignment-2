extends Area2D

@export var warp_to: String = "none"
@export var new_location_group : String = "none"



func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player") || warp_to == "none" || Global.map_holder.is_transition:
		return
	Global.map_holder.change_2d_scene(warp_to, new_location_group, true, false)
