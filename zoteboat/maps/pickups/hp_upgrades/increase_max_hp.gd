extends Area2D

@export var increase_amount: int = 1

signal collected(node)


func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	collect(body)


func collect(body):
	body.change_health(increase_amount, "max")
	
	emit_signal("collected", self)
	self.queue_free()


func connect_collect_signal():
	if !is_connected("collected", Global.map_holder._on_collectable_collected):
		collected.connect(Global.map_holder._on_collectable_collected)
