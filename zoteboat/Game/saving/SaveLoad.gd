extends Node

const save_location = "user://ZoteBoatSave.json"

var contents_to_save: Dictionary = {
	"health": 5,
	
	"starting_room": "res://maps/examples/room transition/main.tscn",
	"starting_location": "start",
	
	"rumble": 2,
	"screen_shake": 2,
	"volume": 2,
	
}

func _save():
	var file = FileAccess.open(save_location, FileAccess.WRITE)
	file.store_var(contents_to_save.duplicate())
	file.close()

func _load():
	if FileAccess.file_exists(save_location):
		var file = FileAccess.open(save_location, FileAccess.READ)
		var data = file.get_var()
		file.close()
		
		for keys in contents_to_save.keys():
			contents_to_save[keys] = data[keys]
