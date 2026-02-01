extends RigidBody2D

func _ready() -> void:
	freeze = true
	await get_tree().physics_frame
	
	$Sprite2D.scale = Vector2(0.7, 0.7)
	freeze = false
	
	linear_velocity = Vector2(
		randf_range(-300, 300),
		randf_range(-400, -200)
	)
