extends Node2D

@export var warp_zones: Array[Area2D]

var warp_to_location: Dictionary[String, String] = {
	"left": "right",
	"right": "left",
	"top": "bottom",
	"bottom": "top",
}


func _ready() -> void:
	var to_remove_warps: Array = []
	for warp in warp_zones:
		if warp.new_location_group == warp_to_location[Global.map_holder.last_location]:
			to_remove_warps.append(warp)
	
	for warp in to_remove_warps:
		warp_zones.erase(warp)
	
	var chosen_warp
	if warp_zones.size() > 0:
		chosen_warp = warp_zones.pick_random()
	else:
		chosen_warp = to_remove_warps.pick_random()
	
	chosen_warp.correct = true
