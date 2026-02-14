extends Node2D

@export var fade_time := 0.75
@export var to_scale: Vector2 = Vector2(0.5, 0.5)

func _ready():
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time).from(0.5)
	tween.parallel().tween_property(self, "scale", to_scale, fade_time).from(Vector2.ONE)
	tween.finished.connect(queue_free)
