extends CharacterBody2D

@export var stats: Stats

signal killed(node: Node2D)

func _ready() -> void:
	if stats != null:
		stats = stats.duplicate(true)
	
	#stats.health_changed.connect(_on_health_changed)
	stats.health_depleted.connect(_on_health_depleted)

func damage(damage_value: int):
	stats.health -= damage_value

func i_frames(time):
	add_to_group("invincible")
	await get_tree().create_timer(time).timeout
	remove_from_group("invincible")


#
#func _on_health_changed(current_health: int, max_health: int):
	#print(str(current_health) + " out of " + str(max_health))

func _on_health_depleted():
	killed.emit(self)
