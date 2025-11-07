extends CharacterBody2D

const gravity := 12;

var gravity_multiplier := 0.0


var is_jumping = false
@export var jump_timer: Timer

func _physics_process(_delta: float) -> void:
	
	
	
#region jumping
	if Input.is_action_just_pressed("jump"):
		velocity = Vector2(0, -350)
		is_jumping = true
		jump_timer.start()
		
	if Input.is_action_just_released("jump"):
		is_jumping = false
	
	if is_jumping:
		gravity_multiplier = 0
		
	else:
		if velocity.y <= 100:
			gravity_multiplier = 2
		else:
			gravity_multiplier = 1
	
	velocity.y += gravity*gravity_multiplier
	
	velocity.y = clamp(velocity.y, -500, 450)
#endregion
	
	
	move_and_slide()




func _on_jump_timer_timeout() -> void:
	is_jumping = false
