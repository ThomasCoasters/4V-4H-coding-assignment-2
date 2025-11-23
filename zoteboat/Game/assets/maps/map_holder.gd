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

func change_2d_scene(new_scene: String, delete: bool = true, keep_running: bool = false) -> void:
	if current_map != null:
		if delete:
			current_map.queue_free() # full remove
		elif keep_running:
			current_map.visible = false # keep in memory and running
		else:
			map.remove_child(current_map)
	var new = load(new_scene).instantiate()
	map.add_child(new)
	current_map = new
