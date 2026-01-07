extends Control
class_name Dialogue


const DIALOGUE_MAIN = preload("uid://cctfjk3xkcwcg")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.dialogue = self


func start(dialogue_name: String = "none"):
	Global.player.can_move = false
	
	var dialogue_main = DIALOGUE_MAIN.instantiate()
	
	self.add_child(dialogue_main)
	
	var dialogue_manager = dialogue_main.dialogue_manager
	
	dialogue_manager.start(dialogue_name)
