extends Control

var HeartScene := preload("res://assets/UI/HP/Heart.tscn")
var hearts: Array[Control] = []
var space_between := 60

var hp: int

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	
	hp = Global.player.health
	setup_ui()
	Global.player.player_health_changed.connect(_on_hp_change)

func setup_ui():
	for i in range(hp):
		var h = HeartScene.instantiate()
		h.position.x = i * space_between
		add_child(h)
		hearts.append(h)
		h.set_full(true)


func _on_hp_change(current_hp):
	for i in range(hearts.size()):
		hearts[i].set_full(i < current_hp)
	hp = current_hp
