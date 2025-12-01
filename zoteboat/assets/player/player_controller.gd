extends CharacterBody2D
class_name Player


#region vars setup
const GRAVITY : int = 12

var gravity_multiplier := 0.0


var is_jumping = false
var jump_timer := Timer.new()
const MAX_JUMP_TIME : float = 0.5
const JUMPING_SPEED : int = -550
@export var max_jumps_amount : int = 1
var jumps_amount : int = max_jumps_amount

@export var max_fall_speed : int = 1200

var direction := Vector2(0,0)
var last_direction := Vector2(1,0)
const MOVE_SPEED : int = 400

@export var Camera : Camera2D
const LOOKAHEAD : int = 50
var current_camera_type := "free" #"free" of "locked"
var forced_position = Vector2(0,0)
const LOOKAHEAD_COOLDOWN : float = 0.1

const ATTACK_COOLDOWN : float = 0.41
const ATTACK_LINGER : float = 0.15

const NORMAL_ATTACK = preload("res://assets/player/attacks/normal attack.tscn")
const UP_ATTACK = preload("res://assets/player/attacks/up attack.tscn")
const DOWN_ATTACK = preload("res://assets/player/attacks/pogo.tscn")

var can_attack : bool = true
var can_move : bool = true
var can_walk : bool = true

const HARDFALL_STUN_TIME : float = 0.6

@export var can_walljump : bool = false
var forced_move : Vector2

@export var attack_damage : int = 5

@export var max_health : int = 5
var health : int: set = _on_health_set
signal player_health_changed(health: int)
#endregion

func _ready() -> void:
	Global.player = self
	setup.call_deferred()
	

func setup():
	#region timers setup
	jump_timer.wait_time = MAX_JUMP_TIME
	jump_timer.one_shot = true
	jump_timer.timeout.connect(_on_jump_timer_timeout)
	add_child(jump_timer)
	#endregion
	health = max_health
	
	$Area2D.body_entered.connect(_on_player_entered)

func _physics_process(_delta: float) -> void:
	
	#region jumping/falling
	var last_vertical_velocity = velocity.y
	
	velocity.y += GRAVITY*gravity_multiplier
	
	velocity.y = clamp(velocity.y, JUMPING_SPEED, max_fall_speed)
	#endregion
	
	#region moving
	if can_walk:
		velocity.x = direction.x*MOVE_SPEED
	else:
		velocity.x = forced_move.x
	
	
	move_and_slide()
	#endregion
	
	if is_on_floor() && last_vertical_velocity > 0:
		_on_landed(last_vertical_velocity)


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
	
	if Input.is_action_just_pressed("attack") && can_attack:
		$StateChart.send_event("attack_start")
	#endregion
		#region checks
	
	if is_on_floor():
		$StateChart.send_event("on_ground")
	if is_on_ceiling():
		$StateChart.send_event("jump_released")
	
	if is_on_wall_only() && velocity.y >0 && can_walljump:
		$StateChart.send_event("on_wall")
	
	if !is_jumping && !is_on_floor():
		$StateChart.send_event("fell_of_platform")
	
	if !is_on_wall() || (is_on_wall() && !test_move(transform, direction)):
		$StateChart.send_event("fell_of_wall")
	
	#endregion
	#endregion
	
	
	camera_movement()
	
	
	#region direction inputs
	direction = Vector2(0,0)
	
	if !can_move:
		return
	
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
	if is_jumping || !can_move || (is_on_wall_only() && velocity.y < 0):
		return
	
	velocity.y = JUMPING_SPEED
	is_jumping = true
	
	jump_timer.start()
	
	gravity_multiplier = 0.5
	
	#current_camera_type = "locked"


func _on_falling_state_entered() -> void:
	jumps_amount -= 1
	
	jump_timer.stop()
	
	is_jumping = false
	
	gravity_multiplier = 3
	
	if !is_jumping:
		return
	velocity.y = 0


func _on_on_ground_state_entered() -> void:
	jumps_amount = max_jumps_amount
	
	#current_camera_type = "free"


func _on_landed(speed):
	if $StateChart/ParallelState/Jumping/hardfall.active && speed >= max_fall_speed:
		can_move = false
		
		await get_tree().create_timer(HARDFALL_STUN_TIME).timeout
		
		can_move = true

func _on_wall_slide_state_entered() -> void:
	velocity.y = 0
	
	gravity_multiplier = 1
	
	jumps_amount = max_jumps_amount
	
	max_fall_speed /= 3

func _on_wall_slide_state_exited() -> void:
	max_fall_speed *= 3
	
	position.x -= last_direction.x

func _on_to_jumping_form_wall_taken() -> void:
	forced_move.x = -last_direction.x * 500
	
	can_walk = false
	
	await get_tree().create_timer(MAX_JUMP_TIME/2).timeout
	
	forced_move.x = 0
	
	can_walk = true

#endregion


#region camera
func camera_movement():
	if current_camera_type != "free":
		Camera.set_as_top_level(true)
		Camera.position = forced_position
		return
		
	Camera.set_as_top_level(false)
	
	camera_movement_y()
	
	if Camera.position.x == last_direction.x*LOOKAHEAD:
		return
	
	
	await get_tree().create_timer(LOOKAHEAD_COOLDOWN).timeout
	
	Camera.position.x = last_direction.x*LOOKAHEAD


func camera_movement_y():
	if !is_on_floor():
		Camera.position.y = 0
		Camera.drag_top_margin = 0.25
		return
	Camera.drag_top_margin = 0
	
	if Camera.position.y == direction.y*LOOKAHEAD*2:
		Camera.position.y = 0
		return
	
	await get_tree().create_timer(LOOKAHEAD_COOLDOWN).timeout
	
	if direction.y == 1:
		Camera.position.y = -direction.y*LOOKAHEAD*2
	else: 
		Camera.position.y = -direction.y*LOOKAHEAD*5
#endregion



#region attacking
func _on_attacking_state_entered() -> void:
	if !can_move:
		$StateChart.send_event("attack_stop")
		return
	
	if direction.y == 1:
		start_UP_ATTACK()
	elif direction.y == -1 && !is_on_floor():
		start_DOWN_ATTACK()
	else:
		start_NORMAL_ATTACK()
	
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	
	$StateChart.send_event("attack_stop")

func delete_attack() -> void:
	for attack in get_tree().get_nodes_in_group("attacks"):
		attack.queue_free()


func start_UP_ATTACK():
	var attack = UP_ATTACK.instantiate()
	attack.position.y = -50
	attack.scale.x = last_direction.x
	
	attack.add_to_group("attacks")
	attack.body_entered.connect(_on_attack_entered)
	
	self.add_child(attack)
	
	await get_tree().create_timer(ATTACK_LINGER).timeout
	
	delete_attack()
	
func start_DOWN_ATTACK():
	var attack = DOWN_ATTACK.instantiate()
	attack.position = position
	attack.scale.x = last_direction.x
	attack.scale.y = -1
	
	attack.add_to_group("attacks")
	attack.body_entered.connect(_on_attack_entered)
	
	get_tree().root.add_child(attack)
	
	attack.pogo_returned.connect(_on_pogo_returned)
	
	velocity.y = JUMPING_SPEED
	
	can_attack = false

func start_NORMAL_ATTACK():
	var attack = NORMAL_ATTACK.instantiate()
	attack.position.x = last_direction.x * 15
	attack.position.y = -10
	attack.scale.x = last_direction.x
	
	attack.add_to_group("attacks")
	attack.body_entered.connect(_on_attack_entered)
	
	self.add_child(attack)
	
	await get_tree().create_timer(ATTACK_LINGER).timeout
	
	delete_attack()


func _on_pogo_returned():
	delete_attack()
	
	can_attack = true


func _on_attack_entered(body: Node2D):
	if !body.is_in_group("enemy"):
		return
	
	change_health(2)
	body.damage(attack_damage)


func change_health(amount):
	health += amount
#endregion


#region HP
func _on_player_entered(body: Node2D):
	if body.is_in_group("enemy"):
		change_health(-body.stats.attack_damage)

func _on_health_set(new_health):
	await get_tree().process_frame
	
	health = clamp(new_health, 0, max_health)
	
	player_health_changed.emit(health)


#endregion
