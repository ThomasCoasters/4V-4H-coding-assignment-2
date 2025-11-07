extends CharacterBody2D

const gravity := 5;

var gravity_multiplier := 0.0


var is_jumping = false

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		velocity = Vector2(0, -300)
		is_jumping = true
	if Input.is_action_just_released("jump"):
		is_jumping = false
	
	if is_jumping:
		gravity_multiplier = 0.7
		
		if velocity.y >= 0:
			is_jumping = false
		
	else:
		if velocity.y <= 0:
			gravity_multiplier = 3
		else:
			gravity_multiplier = 1
	
	velocity.y += gravity*gravity_multiplier
	
	velocity.y = clamp(velocity.y, -500, 300)
	
	move_and_slide()
	
	print(velocity.y)
