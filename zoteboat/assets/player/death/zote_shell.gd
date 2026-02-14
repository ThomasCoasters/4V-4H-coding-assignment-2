extends RigidBody2D

func _ready() -> void:
	linear_velocity = Vector2(
		randf_range(-300, 300),
		randf_range(-700, -500)
	)
	
	angular_velocity = randf_range(-deg_to_rad(500), deg_to_rad(500))
