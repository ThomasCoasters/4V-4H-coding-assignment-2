extends Node2D

@export var stats: Stats

@export var orbit_radius := 40.0
@export var orbit_speed := 4.0

func _ready() -> void:
	var areas = $Orbit.get_children()
	for i in areas.size():
		var angle := i * TAU / areas.size()
		areas[i].position = Vector2(orbit_radius, 0).rotated(angle)

func _physics_process(delta: float) -> void:
	$Orbit.rotation += orbit_speed * delta


func set_circle_attack_enabled(enabled: bool) -> void:
	visible = enabled
	
	for area in $Orbit.get_children():
		if area is Area2D:
			for child in area.get_children():
				if child is CollisionShape2D:
					child.set_deferred("disabled", !enabled)
