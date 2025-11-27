extends Control

var HP_lost_scene = preload("res://assets/player/UI/HP/assets/HP_lost.tscn")
var HP_over_scene = preload("res://assets/player/UI/HP/assets/HP_over.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	print("changed player")
	Global.player.player_health_changed.connect(_on_player_hp_change)

func _on_player_hp_change(current_health, _max_health):
	print_debug(current_health)
	var next_position = 0
	for HP in range(current_health):
		var HP_over = HP_over_scene.instantiate()
		HP_over.position.x = next_position
		self.add_child(HP_over)
		
		next_position += 10
	
	
