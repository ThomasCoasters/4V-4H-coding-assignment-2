extends Control

var HeartScene := preload("res://assets/UI/HP/Heart.tscn")
var hearts: Array[Control] = []

var space_between := 50

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	

	_on_max_hp_change()
	Global.player.player_health_changed.connect(_on_hp_change)
	Global.player.player_max_health_changed.connect(_on_max_hp_change)

func _on_max_hp_change():
	delete_old()
	
	for i in range(Global.player.max_health):
		var h = HeartScene.instantiate()
		h.position.x = i * space_between
		add_child(h)
		hearts.append(h)
		h.set_full(true)

func _on_hp_change(current_hp):
	await get_tree().process_frame
	
	for i in range(hearts.size()):
		hearts[i].set_full(i < current_hp)


func delete_old():
	for i in range(hearts.size()):
		hearts[0].queue_free()
		hearts.remove_at(0)
