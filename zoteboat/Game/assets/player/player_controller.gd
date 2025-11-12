extends CharacterBody2D

@export var gravity := 12;

var gravity_multiplier := 0.0


var is_jumping = false
var jump_timer := Timer.new()
@export var max_jump_time = 0.7
@export var jumping_speed := -350
@export var max_jumps_amount := 2
var jumps_amount : int = max_jumps_amount

@export var max_fall_speed = 550



func _ready() -> void:
	
	
	#region timers setup
	jump_timer.wait_time = max_jump_time
	jump_timer.one_shot = true
	jump_timer.timeout.connect(_on_jump_timer_timeout)
	add_child(jump_timer)
	#endregion



func _physics_process(_delta: float) -> void:
	#region jumping
	velocity.y += gravity*gravity_multiplier
	
	velocity.y = clamp(velocity.y, jumping_speed, 450)
	#endregion
	
	
	move_and_slide()


func _process(_delta: float) -> void:
	#region inputs
	if Input.is_action_just_pressed("jump"):
		$StateChart.send_event("jump_clicked")
	
	if Input.is_action_just_released("jump"):
		print(jumps_amount)
		$StateChart.set_expression_property("jumps_amount", jumps_amount)
		$StateChart.send_event("jump_released")
	#endregion




func _on_jump_timer_timeout() -> void:
	$StateChart.send_event("jump_released")


func _on_jump_state_entered() -> void:
	jumps_amount -= 1
	
	velocity.y = jumping_speed
	is_jumping = true
	
	jump_timer.start()
	
	gravity_multiplier = 0


func _on_falling_state_entered() -> void:
	is_jumping = false
	
	gravity_multiplier = 1
	
	velocity.y *= 0.5


func _on_on_ground_state_entered() -> void:
	jumps_amount = max_jumps_amount
