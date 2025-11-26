extends Control

var HP_lost = preload("res://assets/player/UI/HP/assets/HP_lost.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.player.player_health_changed.connect(_on_player_hp_change)

func _on_player_hp_change(current_health, max_health):
	var next_position = 0
	for HP in current_health:
		var HP_over = preload("res://assets/player/UI/HP/assets/HP_over.tscn")
		HP_over.position = next_position
		self.add_child(HP_over)
		
		next_position += 10
	
	
