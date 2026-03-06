extends Area2D

@onready var point_light_2d: PointLight2D = $PointLight2D


@export var possible_warping: Array[String]
var warp_to: String = "none"
@export var new_location_group : String = "none"

@export var correct:bool = false

func _ready() -> void:
	possible_warping.shuffle()
	warp_to = possible_warping[0]
	
	if !correct:
		point_light_2d.enabled = false

func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player") || warp_to == "none" || Global.map_holder.is_transition:
		return
	if !correct:
		warp_to = "res://maps/maps/mist/mist_start.tscn"
		new_location_group = "spawn"
		Global.player.mist_correct = 0
	
	else:
		Global.player.mist_correct += 1
	
	Global.map_holder.change_2d_scene(warp_to, new_location_group, true, false)
