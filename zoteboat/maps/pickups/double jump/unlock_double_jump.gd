extends Area2D

signal collected(node)

@export var own_spawning_group: String = "double_jump"

var has_double_jump: bool = false

func _ready() -> void:
	has_double_jump = SaveLoad.contents_to_save.has_double_jump
	
	add_to_group(own_spawning_group)

func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	collect(body)


func collect(body):
	has_double_jump = true
	body.has_double_jump = true
	
	SaveLoad.contents_to_save.has_double_jump = has_double_jump
	SaveLoad.contents_to_save.starting_room = Global.map.scene_file_path
	SaveLoad.contents_to_save.starting_location = own_spawning_group
	
	SaveLoad._save()
	
	collected.emit(self)
