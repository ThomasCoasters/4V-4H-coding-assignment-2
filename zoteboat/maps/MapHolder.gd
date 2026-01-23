class_name MapHolder extends Node

@export var map : Node2D
@export var player : CharacterBody2D
@export var gui : Control

var current_map
var current_GUI

var killed_enemies : Dictionary = {}
var respawnable_enemies : Dictionary = {}

var finished_arenas : Dictionary = {}

var collected_items : Dictionary = {}

var is_transition: bool = false

func _ready() -> void:
	Global.map_holder = self
	
	map_just_loaded()
	
	current_map = $map/TestMap
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func change_gui_scene(new_scene: String, delete: bool = true, keep_running: bool = false) -> void:
	if current_GUI != null:
		if delete:
			current_GUI.queue_free() # full remove
		elif keep_running:
			current_GUI.visible = false # keep in memory and running
		else:
			gui.remove_child(current_GUI)
	var new = load(new_scene).instantiate()
	gui.add_child(new)
	current_GUI = new

func change_2d_scene(new_scene: String, new_location_group: String, delete: bool = true, keep_running: bool = false) -> void:
	call_deferred("_change_2d_scene_internal", new_scene, new_location_group, delete, keep_running)


func _change_2d_scene_internal(new_scene, new_location_group, delete, keep_running):
	is_transition = true
	
	fading()
	
	await transition.on_transition_finished
	player.global_position = Vector2(-100000, -100000)
	
	
	if current_map != null:
		if delete:
			current_map.queue_free()
		elif keep_running:
			current_map.visible = false
		else:
			map.remove_child(current_map)
	
	
	if new_scene == "none":
		return
	
	var new = load(new_scene).instantiate()
	map.add_child(new)
	current_map = new
	
	_disable_map_transitions(new)

	
	get_tree().call_group("projectiles", "queue_free")
	
	for child in new.get_children():
		if child.is_in_group(new_location_group):
			Global.player.set_hazard_respawn()
			
			player.global_position = child.global_position
			continue
		
		if child is NavigationAgent2D:
			Global.navigation_agent_2d = child
	
	map_just_loaded()
	
	await transition.on_transition_finished
	
	player.can_move = true
	player.remove_from_group("invincible")
	player.set_process_mode(Node.PROCESS_MODE_INHERIT)
	player.Camera.set_process_mode(Node.PROCESS_MODE_INHERIT)
	
	await get_tree().physics_frame
	get_tree().call_group("map_transitions", "set_deferred", "monitoring", true)
	await get_tree().physics_frame
	
	is_transition = false



func fading():
	transition.transition()
	player.can_move = false
	player.add_to_group("invincible")
	player.set_process_mode(Node.PROCESS_MODE_DISABLED)
	player.Camera.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	
	get_tree().call_group("map_transitions", "set_deferred", "monitoring", false)




#region respawn or not
func map_just_loaded():
	if Global.map.enemy_died.is_connected(_on_enemy_killed):
		Global.map.enemy_died.disconnect(_on_enemy_killed)
	if Global.map.arena_won.is_connected(_on_arena_won):
		Global.map.arena_won.disconnect(_on_arena_won)
	if Global.map.item_collected.is_connected(_on_item_collected):
		Global.map.item_collected.disconnect(_on_item_collected)
	
	
	
	Global.map.enemy_died.connect(_on_enemy_killed)
	Global.map.arena_won.connect(_on_arena_won)
	Global.map.item_collected.connect(_on_item_collected)



func _on_enemy_killed(enemy: Node2D):
	var map_path = current_map.scene_file_path
	var enemy_path = str(enemy.get_path())
	
	if !killed_enemies.has(map_path):
		killed_enemies[map_path] = []
	if !respawnable_enemies.has(map_path):
		respawnable_enemies[map_path] = []
	
	if !enemy.stats.respawn_every_room:
		if enemy.stats.respawn_every_save:
			respawnable_enemies[map_path].append(enemy_path)
		killed_enemies[map_path].append(enemy_path)


func _on_arena_won(arena):
	var map_path = current_map.scene_file_path
	var arena_path = str(arena.get_path())
	
	if !finished_arenas.has(map_path):
		finished_arenas[map_path] = []
	
	finished_arenas[map_path].append(arena_path)

func _on_item_collected(item):
	var map_path = current_map.scene_file_path
	var item_path = str(item.get_path())
	
	if !collected_items.has(map_path):
		collected_items[map_path] = []
	
	collected_items[map_path].append(item_path)
#endregion





func _disable_map_transitions(map_node: Node) -> void:
	for t in map_node.get_tree().get_nodes_in_group("map_transitions"):
		t.set_deferred("monitoring", false)
