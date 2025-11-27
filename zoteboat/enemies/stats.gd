extends Resource
class_name Stats

signal health_depleted
signal health_changed(current_health: int, max_health: int)

@export var max_health: int = 10

@export var respawn_every_room: bool = false
@export var respawn_every_save: bool = true

@export var attack_damage: int = 1

var health: int = 0: set = _on_health_set

func _init() -> void:
	setup_stats.call_deferred()

func setup_stats() -> void:
	health = max_health

func _on_health_set(new_value: int) -> void:
	health = clamp(new_value, 0, max_health)
	health_changed.emit(health, max_health)
	if health <= 0:
		health_depleted.emit()
