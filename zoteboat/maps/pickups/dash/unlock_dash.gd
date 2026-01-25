extends Area2D

signal collected(node)

@export var own_spawning_group: String = "dash"

var has_dash: bool = false

func _ready() -> void:
	has_dash = SaveLoad.contents_to_save.has_dash
	
	add_to_group(own_spawning_group)

func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	collect(body)


func collect(body):
	has_dash = true
	body.has_dash = true
	
	SaveLoad.contents_to_save.has_dash = has_dash
	SaveLoad.contents_to_save.starting_room = Global.map.scene_file_path
	SaveLoad.contents_to_save.starting_location = own_spawning_group
	
	SaveLoad._save()
	
	collected.emit(self)
