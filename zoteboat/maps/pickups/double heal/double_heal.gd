extends Area2D

@export var increase_amount: int = 1

signal collected(node)


func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	collect(body)


func collect(body):
	SaveLoad.contents_to_save.heal_health += increase_amount
	SaveLoad._save()
	
	body.heal_health = SaveLoad.contents_to_save.heal_health
	
	collected.emit(self)
