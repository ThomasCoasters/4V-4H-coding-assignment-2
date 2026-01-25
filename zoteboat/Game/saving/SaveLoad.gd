extends Node

const save_location = "user://ZoteBoatSave.json"

var DEFAULT_SAVE: Dictionary = {
	"max_health": 5,
	
	"starting_room": "res://maps/examples/room transition/main.tscn",
	"starting_location": "start",
	
	"rumble": 2,
	"screen_shake": 2,
	"volume": 2,
	
	"killed_enemies": {},
	"finished_arenas": {},
	"collected_items": {}
}

var contents_to_save: Dictionary = DEFAULT_SAVE.duplicate(true)



func _ready() -> void:
	_load()



func _save():
	var file = FileAccess.open(save_location, FileAccess.WRITE)
	file.store_var(contents_to_save.duplicate())
	file.close()

func _load():
	if not FileAccess.file_exists(save_location):
		_save()
		return
	
	var file = FileAccess.open(save_location, FileAccess.READ)
	var loaded: Dictionary = file.get_var()
	file.close()
	
	contents_to_save.merge(loaded, true)



func reset_save() -> void:
	contents_to_save = DEFAULT_SAVE.duplicate(true)
	_save()
