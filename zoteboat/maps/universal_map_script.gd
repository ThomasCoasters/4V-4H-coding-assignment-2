extends Node2D
class_name Map

signal enemy_died(enemy: Node2D)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.map = self
	
	var map_path = scene_file_path
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		
		var full_path = str(enemy.get_path())
		
		if Global.map_holder.killed_enemies.has(map_path):
			if full_path in Global.map_holder.killed_enemies[map_path]:
				enemy.queue_free()
				continue
			
		enemy.killed.connect(_on_enemy_killed)


func _on_enemy_killed(enemy: Node2D):
	enemy_died.emit(enemy)
	enemy.queue_free()
