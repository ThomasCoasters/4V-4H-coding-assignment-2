extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	
	body.change_health(1, "max")
	
	self.queue_free()
