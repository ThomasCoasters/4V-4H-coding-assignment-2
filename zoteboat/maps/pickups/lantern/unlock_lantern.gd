extends Area2D

signal collected(node)

@export var own_spawning_group: String = "lantern"

var has_lantern: bool = false

func _ready() -> void:
	has_lantern = SaveLoad.contents_to_save.has_lantern
	
	add_to_group(own_spawning_group)
	
	if has_lantern:
		visible = false

func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	if body.has_lantern:
		return
	
	collect(body)


func collect(body):
	has_lantern = true
	body.has_lantern = true
	body.point_light_2d.texture_scale = 19.0
	
	SaveLoad.contents_to_save.has_lantern = has_lantern
	SaveLoad.contents_to_save.starting_room = Global.map.scene_file_path
	SaveLoad.contents_to_save.starting_location = own_spawning_group
	
	SaveLoad._save()
	
	Global.dialogue.start("lantern_unlock")
	
	collected.emit(self)
	
