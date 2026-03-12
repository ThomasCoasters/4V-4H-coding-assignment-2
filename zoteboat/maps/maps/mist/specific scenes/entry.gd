extends Area2D

@export var warp_to_normal: String = "none"
@export var warp_to_post_mist: String = "none"

@export var new_location_group : String = "none"



func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player") || warp_to_normal == "none" || Global.map_holder.is_transition:
		return
	
	if SaveLoad.contents_to_save.mist_completed == true:
		Global.map_holder.change_2d_scene(warp_to_post_mist, new_location_group, true, false)
	else:
		Global.map_holder.change_2d_scene(warp_to_normal, new_location_group, true, false)
