class_name MapHolder extends Node

@export var map : Node2D
@export var player : CharacterBody2D
@export var gui : Control
@export var audio : AudioStreamPlayer

var current_map
var current_GUI

var killed_enemies : Dictionary = {}
var respawnable_enemies : Dictionary = {}

var finished_arenas : Dictionary = {}

var collected_items : Dictionary = {}

var last_death_positions := {}

var is_transition: bool = false

var audio_path: String



func _ready() -> void:
	killed_enemies = SaveLoad.contents_to_save.killed_enemies.duplicate(true)
	finished_arenas = SaveLoad.contents_to_save.finished_arenas.duplicate(true)
	collected_items = SaveLoad.contents_to_save.collected_items.duplicate(true)
	
	
	Global.map_holder = self
	
	player.visible = false
	player.ui_holder.visible = false
	
	player.can_move = false
	player.add_to_group("invincible")
	player.set_process_mode(Node.PROCESS_MODE_DISABLED)
	player.Camera.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func change_gui_scene(new_scene: String, delete: bool = true, keep_running: bool = false) -> void:
	if gui.get_child_count() > 0:
		return
	
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
	player.visible = true
	player.ui_holder.visible = true
	player.global_position = Vector2(-100000, -100000)
	
	if player.death_shell != null && player.death_shell.is_inside_tree():
		player.death_shell.queue_free()
		player.death_shell = null
	
	
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
			player.global_position = child.global_position
			Global.player.set_hazard_respawn()
			continue
		
		if child is NavigationAgent2D:
			Global.navigation_agent_2d = child
		
		if child is TileMapLayer:
			Global.player.Camera.setup_limits(child)
	
	map_just_loaded()
	
	await transition.on_transition_finished
	
	player.can_move = true
	player.sprite_2d.visible = true
	player.remove_from_group("invincible")
	player.set_process_mode(Node.PROCESS_MODE_INHERIT)
	player.Camera.set_process_mode(Node.PROCESS_MODE_INHERIT)
	player.Camera.position_smoothing_enabled = true
	
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
	player.Camera.position_smoothing_enabled = false
	
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
			return
		killed_enemies[map_path].append(enemy_path)
		SaveLoad.contents_to_save.killed_enemies = killed_enemies.duplicate(true)
		SaveLoad._save()


func _on_arena_won(arena):
	var map_path = current_map.scene_file_path
	var arena_path = str(arena.get_path())
	
	if !finished_arenas.has(map_path):
		finished_arenas[map_path] = []
	
	finished_arenas[map_path].append(arena_path)
	
	SaveLoad.contents_to_save.finished_arenas = finished_arenas.duplicate(true)
	SaveLoad._save()

func _on_item_collected(item):
	var map_path = current_map.scene_file_path
	var item_path = str(item.get_path())
	
	if !collected_items.has(map_path):
		collected_items[map_path] = []
	
	collected_items[map_path].append(item_path)
	
	SaveLoad.contents_to_save.collected_items = collected_items.duplicate(true)
	SaveLoad._save()
#endregion





func _disable_map_transitions(map_node: Node) -> void:
	for t in map_node.get_tree().get_nodes_in_group("map_transitions"):
		t.set_deferred("monitoring", false)



func new_audio(path: String):
	audio_path = path
	
	audio.stream = load(path)
	audio.play()



func record_player_death(pos: Vector2):
	var scene_path = current_map.scene_file_path
	
	if !last_death_positions.has(scene_path):
		last_death_positions[scene_path] = []
	
	if last_death_positions[scene_path].size() >= 3:
		last_death_positions[scene_path].remove_at(0)
	
	last_death_positions[scene_path].append(pos)
