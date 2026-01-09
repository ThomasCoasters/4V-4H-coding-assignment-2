extends Node2D

var entered: bool = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	entered = true



func _on_area_2d_body_exited(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	entered = false


func _process(_delta: float) -> void:
	if !entered:
		return
	
	if Global.player.direction.y == 1 && !Global.player.moving.active:
		Global.dialogue.start("test")
