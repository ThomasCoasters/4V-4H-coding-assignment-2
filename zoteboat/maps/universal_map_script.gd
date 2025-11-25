extends Node2D
class_name Map

signal enemy_died(enemy: Node2D)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MapGlobal.map = self
	
	for child in get_children():
		if child.is_in_group("enemy"):
			child.killed.connect(_on_enemy_killed)


func _on_enemy_killed(enemy: Node2D):
	print(enemy)
	enemy_died.emit(enemy)
	enemy.queue_free()
