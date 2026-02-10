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




func set_circle_attack_enabled(enabled: bool, time: float = 0.4) -> void:
	var areas = $Orbit.get_children()
	for i in areas.size():
		var angle := i * TAU / areas.size()
		areas[i].position = Vector2(orbit_radius, 0).rotated(angle)
	
	
	var to_modulate: float = 1.0
	var from_modulate: float = 0.0
	var to_scale: Vector2 = Vector2.ONE
	var from_scale: Vector2 = Vector2.ZERO
	if !enabled:
		enable_areas(enabled)
		to_modulate = 0.0
		from_modulate = 1.0
		to_scale = Vector2.ZERO
		from_scale = Vector2.ONE
	
	
	var tween := get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "modulate:a", to_modulate, time). from(from_modulate)
	tween.parallel().tween_property(self, "scale", to_scale, time).from(from_scale)
	tween.finished.connect(func():
		if enabled:
			enable_areas(enabled)
	)

func enable_areas(enabled: bool):
	for area in $Orbit.get_children():
		if area is Area2D:
			for child in area.get_children():
				if child is CollisionShape2D:
					child.set_deferred("disabled", !enabled)
