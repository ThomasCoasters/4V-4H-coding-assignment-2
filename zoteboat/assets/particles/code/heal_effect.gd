extends GPUParticles2D

func _physics_process(_delta: float) -> void:
	global_position = Global.player.global_position + Vector2(0, 20)
	
	if Global.player.heal_idle.active && emitting:
		emitting = false
		await get_tree().create_timer(0.3).timeout
		
		queue_free()
