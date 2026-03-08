extends Area2D

@export var increase_amount: int = 2

signal collected(node)


func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	collect(body)


func collect(body):
	SaveLoad.contents_to_save.damage += increase_amount
	
	SaveLoad._save()
	
	body.attack_damage = SaveLoad.contents_to_save.damage
	
	collected.emit(self)
