extends RigidBody2D

func _ready() -> void:
	linear_velocity = Vector2(
		randf_range(-300, 300),
		randf_range(-400, -200)
	)
