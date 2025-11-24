extends Area2D

@export var stats: Stats

func _ready() -> void:
	stats.health_changed.connect(_on_health_changed)
	stats.health_depleted.connect(_on_health_depleted)

func damage(damage_value: int):
	stats.health -= damage_value

func _on_health_changed(current_health: int, max_health: int):
	print(str(current_health) + " out of " + str(max_health))

func _on_health_depleted():
	queue_free()
