extends Area2D

signal collected(node)

@export var own_spawning_group: String = "wall_cling"

var has_wall_cling: bool = false

func _ready() -> void:
	has_wall_cling = SaveLoad.contents_to_save.has_wall_cling
	
	add_to_group(own_spawning_group)

func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	if body.has_wall_cling:
		return
	
	collect(body)


func collect(body):
	has_wall_cling = true
	body.has_wall_cling = true
	
	SaveLoad.contents_to_save.has_wall_cling = has_wall_cling
	SaveLoad.contents_to_save.starting_room = Global.map.scene_file_path
	SaveLoad.contents_to_save.starting_location = own_spawning_group
	
	SaveLoad._save()
	
	Global.dialogue.start("walljump_unlock")
	
	collected.emit(self)
