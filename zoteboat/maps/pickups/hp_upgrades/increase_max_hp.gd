extends Area2D

@export var increase_amount: int = 1

signal collected(node)


func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	
	body.change_health(increase_amount, "max")
	
	
	emit_signal("collected", self)
	self.queue_free()
