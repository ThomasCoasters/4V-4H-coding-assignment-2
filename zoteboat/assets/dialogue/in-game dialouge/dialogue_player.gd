extends Control
class_name Dialogue


const DIALOGUE_MAIN = preload("uid://cctfjk3xkcwcg")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.dialogue = self


func start(dialogue_name: String = "none"):
	if !Global.player.is_on_floor() && !(dialogue_name == "dash_unlock" || dialogue_name == "walljump_unlock" || dialogue_name == "doublejump_unlock"):
		return
	
	Global.player.can_move = false
	
	var dialogue_main = DIALOGUE_MAIN.instantiate()
	
	self.add_child(dialogue_main)
	
	var dialogue_manager = dialogue_main.dialogue_manager
	
	dialogue_manager.start(dialogue_name)
	
	var max_size = Global.player.talking_noises.size()-1
	Global.player.play_audio(Global.player.talking_noises[randi_range(0, max_size)])
