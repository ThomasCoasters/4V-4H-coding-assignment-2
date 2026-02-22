extends Node

const save_location = "user://ZoteBoatSave.json"

var DEFAULT_SAVE: Dictionary = {
	"max_health": 5,
	#"max_health": 1,
	
	"has_dash": false,
	"has_double_jump": false,
	"has_wall_cling": false,
	
	#"starting_room": "res://maps/maps/pre-dash/kingspass_for_losers.tscn",
	#"starting_room": "res://maps/maps/Circus/Circus_1.tscn",
	"starting_room": "res://maps/maps/P.o.B/room_3.tscn",
	
	#"starting_location": "start_1,-1",
	#"starting_location": "bench",
	"starting_location": "left_P.o.B",
	
	"rumble": 2,
	"screen_shake": 2,
	
	"master_volume": 10,
	"sound_volume": 10,
	"music_volume": 10,
	
	"unkillable": 0,
	"invis": 0,
	"permadeath": 0,
	
	"killed_enemies": {},
	"finished_arenas": {},
	"collected_items": {},
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
