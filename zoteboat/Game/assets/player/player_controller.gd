extends CharacterBody2D

#region vars setup
@export var gravity : int;

var gravity_multiplier := 0.0


var is_jumping = false
var jump_timer := Timer.new()
@export var max_jump_time : float
@export var jumping_speed : int
@export var max_jumps_amount : int
var jumps_amount : int = max_jumps_amount

@export var max_fall_speed : int

var direction := Vector2(0,0)
var last_direction := Vector2(1,0)
@export var move_speed : int

@export var Camera : Camera2D
@export var lookahead : int
var current_camera_type := "free" #"free" of "locked"
var forced_position = Vector2(0,0)
var lookahead_timer := Timer.new()
@export var lookahead_cooldown : float

var attack_timer := Timer.new()
@export var attack_cooldown : float
#endregion

func _ready() -> void:
	#region timers setup
	jump_timer.wait_time = max_jump_time
	jump_timer.one_shot = true
	jump_timer.timeout.connect(_on_jump_timer_timeout)
	add_child(jump_timer)
	
	lookahead_timer.wait_time = lookahead_cooldown
	lookahead_timer.one_shot = true
	lookahead_timer.timeout.connect(_on_lookahead_timer_timeout)
	add_child(lookahead_timer)
	
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	#endregion



func _physics_process(_delta: float) -> void:
	#region jumping
	velocity.y += gravity*gravity_multiplier
	
	velocity.y = clamp(velocity.y, jumping_speed, max_fall_speed)
	#endregion
	
	#region moving
	velocity.x = direction.x*move_speed

	
	move_and_slide()
	#endregion


func _process(_delta: float) -> void:
	#region state machine events
		#region inputs
	
	if Input.is_action_just_pressed("jump"):
		$StateChart.set_expression_property("jumps_amount", jumps_amount)
		$StateChart.send_event("jump_clicked")
	
	if Input.is_action_just_released("jump"):
		$StateChart.send_event("jump_released")
	
	if Input.is_action_just_pressed("left") || Input.is_action_just_pressed("right"):
		$StateChart.send_event("moving_clicked")
	
	if !Input.is_action_pressed("left") && !Input.is_action_pressed("right"):
		$StateChart.send_event("moving_released")
	
	if Input.is_action_just_pressed("attack"):
		$StateChart.send_event("attack_start")
	#endregion
		#region checks
	
	if is_on_floor():
		$StateChart.send_event("on_ground")
	if is_on_ceiling():
		$StateChart.send_event("jump_released")
	
	if !is_jumping && !is_on_floor():
		$StateChart.send_event("fell_of_platform")
	
	#endregion
	#endregion
	
	
	camera_movement()
	
	
	#region direction inputs
	direction = Vector2(0,0)
	
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("right"):
		direction.x += 1
	
	if Input.is_action_pressed("down"):
		direction.y -= 1
	if Input.is_action_pressed("up"):
		direction.y += 1
	
	if direction.x != 0:
		last_direction.x = direction.x
	#endregion
	



#region jumping/falling/on_ground
func _on_jump_timer_timeout() -> void:
	$StateChart.send_event("jump_released")


func _on_jump_state_entered() -> void:
	if is_jumping:
		return
	
	velocity.y = jumping_speed
	is_jumping = true
	
	jump_timer.start()
	
	gravity_multiplier = 0.5
	
	#current_camera_type = "locked"


func _on_falling_state_entered() -> void:
	jumps_amount -= 1
	
	jump_timer.stop()
	
	is_jumping = false
	
	gravity_multiplier = 4
	
	if !is_jumping:
		return
	velocity.y *= 0.5


func _on_on_ground_state_entered() -> void:
	jumps_amount = max_jumps_amount
	
	#current_camera_type = "free"
#endregion


#region camera
func _on_lookahead_timer_timeout():
	Camera.position.x = last_direction.x*lookahead

func camera_movement():
	if current_camera_type != "free":
		Camera.set_as_top_level(true)
		Camera.position = forced_position
		return
		
	Camera.set_as_top_level(false)
	
	if Camera.position.x == last_direction.x*lookahead:
		return
	if lookahead_timer.is_stopped():
		lookahead_timer.start()
#endregion



func _on_attacking_state_entered() -> void:
	attack_timer.start()
	
	if direction.y == 1:
		start_up_attack()
	elif direction.y == -1 && !is_on_floor():
		start_down_attack()
	else:
		start_normal_attack()

func _on_attack_timer_timeout():
	$StateChart.send_event("attack_stop")

func start_up_attack():
	print("up attack")
	
func start_down_attack():
	print("down attack")
	
func start_normal_attack():
	print("normal attack " + str(last_direction.x))
