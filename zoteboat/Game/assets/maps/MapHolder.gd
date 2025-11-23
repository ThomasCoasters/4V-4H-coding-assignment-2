class_name MapHolder extends Node

@export var map : Node2D
@export var player : CharacterBody2D
@export var gui : Control

var current_map
var current_GUI

func _ready() -> void:
	Global.map_holder = self
	current_map = $map/TestMap

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

	for child in new.get_children():
		if child.is_in_group(new_location_group):
			player.position = child.position
			return
	
	print_debug("no location to warp to " + str(new_location_group))
