extends Node2D

@export var damage: int = 1
@export var sawblade: bool = false

func _ready() -> void:
	if sawblade:
		$Control.get_children().pick_random().playing = true

func _on_static_body_2d_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player") || Global.map_holder.is_transition:
		return
	
	
	body.on_spikes_entered(damage)
