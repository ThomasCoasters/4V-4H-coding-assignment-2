extends Node2D
class_name Map

signal enemy_died(enemy: Node2D)
signal arena_won(arena: Node)
signal item_collected(item: Node)

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
		if Global.map_holder.respawnable_enemies.has(map_path):
			if full_path in Global.map_holder.respawnable_enemies[map_path]:
				enemy.queue_free()
				continue
		
		
		enemy.killed.connect(_on_enemy_killed)
	
	for arena in get_tree().get_nodes_in_group("enemy arena"):
		var parent = arena.get_parent()
		var full_path = str(parent.get_path())
		
		if Global.map_holder.finished_arenas.has(map_path):
			if full_path in Global.map_holder.finished_arenas[map_path]:
				parent.queue_free()
				continue
		
		arena.arena_won.connect(_on_arena_won)
	
	
	for item in get_tree().get_nodes_in_group("collectable"):
		
		var full_path = str(item.get_path())
		
		if Global.map_holder.collected_items.has(map_path):
			if full_path in Global.map_holder.collected_items[map_path]:
				item.queue_free()
				continue
		
		item.collected.connect(_on_item_collected)
	
	
	


func _on_enemy_killed(enemy: Node2D):
	enemy_died.emit(enemy)
	enemy.queue_free()


func _on_arena_won(arena):
	arena_won.emit(arena)
	arena.queue_free()

func _on_item_collected(item):
	item_collected.emit(item)
	item.queue_free()
