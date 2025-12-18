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
var normal_max_fall_speed: int = max_fall_speed

var direction := Vector2(0,0)
var last_direction := Vector2(1,0)
const MOVE_SPEED : int = 400

@export var Camera : Camera2D
const LOOKAHEAD : int = 50
var current_camera_type := "free" #"free" of "locked"
var forced_position = Vector2(0,0)
const LOOKAHEAD_COOLDOWN : float = 0.1

var attack_cooldown : float = 0.41
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

@export var max_health : int = 5: set = _on_max_health_set
var health : int: set = _on_health_set
signal player_health_changed(health: int)
signal player_max_health_changed()

@export var i_frames_hit_time: float = 1.2
@export var hitstun_time: float = 0.05

const GET_HIT_KNOCKBACK_FORCE = 300
const GET_HIT_KNOCKBACK_TIME = 0.1

const ATTACK_KNOCKBACK_FORCE = 300
const ATTACK_KNOCKBACK_TIME = 0.05


@export var mana_per_attack: int = 11
@export var max_mana : int = 99: set = _on_max_mana_set
var mana : int: set = _on_mana_set
signal player_mana_changed(mana: int)
signal player_max_mana_changed()

@export var mana_to_heal : int = 33
@export var heal_time : float = 1.2

var heal_time_expired: float = 0

var mana_float = float(mana)

@export var heal_health: int = 1

var healing_max_fall_speed_multiplier: int = 6
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
	
	for body in $Area2D.get_overlapping_bodies():
		_on_player_entered(body)


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
	
	
	if Input.is_action_just_pressed("specials") && can_move:
		if $StateChart/ParallelState/attacking/Idle.active && mana >= mana_to_heal:
			$StateChart.send_event("heal_start")
	
	if Input.is_action_just_released("specials"):
		$StateChart.send_event("heal_cancel")
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
	
	gravity_multiplier = 0.1
	
	jumps_amount = max_jumps_amount
	
	max_fall_speed /= 5

func _on_wall_slide_state_exited() -> void:
	max_fall_speed *= 5
	
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
	elif direction.y == -1 && !is_on_floor() && !$StateChart/ParallelState/Jumping/wall_slide.active:
		start_DOWN_ATTACK()
	else:
		start_NORMAL_ATTACK()
	
	await get_tree().create_timer(attack_cooldown).timeout
	
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
	if !$StateChart/ParallelState/Jumping/wall_slide.active:
		attack.position.x = last_direction.x * 15
		attack.scale.x = last_direction.x
	else:
		attack.position.x = -last_direction.x * 15
		attack.scale.x = -last_direction.x
	
	attack.position.y = -10
	
	attack.add_to_group("attacks")
	attack.body_entered.connect(_on_attack_entered)
	
	self.add_child(attack)
	
	await get_tree().create_timer(ATTACK_LINGER).timeout
	
	delete_attack()


func _on_pogo_returned():
	delete_attack()
	
	can_attack = true


func _on_attack_entered(body: Node2D):
	if !body.is_in_group("enemy") || body.is_in_group("invincible"):
		return
	
	knockback(ATTACK_KNOCKBACK_FORCE, ATTACK_KNOCKBACK_TIME, body, false)
	
	body.damage(attack_damage)
	body.i_frames(attack_cooldown)
	
	add_mana(mana_per_attack)

#endregion


#region HP
func change_health(amount: int, type: String = "normal"):
	if type == "max":
		max_health += amount
	else:
		health += amount


func _on_player_entered(body: Node2D):
	if self.is_in_group("invincible"):
		return
	
	if body.is_in_group("enemy"):
		change_health(-body.stats.attack_damage)
		
		hitstop_manager(hitstun_time)
		knockback(GET_HIT_KNOCKBACK_FORCE, GET_HIT_KNOCKBACK_TIME, body, true)
		i_frames(i_frames_hit_time)

func _on_health_set(new_health):
	health = clamp(new_health, 0, max_health)
	
	player_health_changed.emit(health)

func _on_max_health_set(new_max_health):
	max_health = new_max_health
	
	health = max_health
	
	player_max_health_changed.emit()

func _on_heal_start_state_physics_processing(delta: float) -> void:
	add_mana(-mana_to_heal * (delta/heal_time))
	
	heal_time_expired += delta
	
	if heal_time_expired >= heal_time-delta:
		$StateChart.send_event("heal_finished")

func _on_heal_start_state_entered() -> void:
	$Sprite2D.set_modulate(Color8(0,255,0))
	
	heal_time_expired = 0
	
	can_move = false
	
	max_fall_speed /= healing_max_fall_speed_multiplier
	velocity.y = 50

func _on_heal_finished_state_entered() -> void:
	change_health(heal_health)
	$Sprite2D.set_modulate(Color8(255,255,255))
	
	attack_speed_buff()

func _on_idle_state_entered() -> void:
	can_move = true
	max_fall_speed = normal_max_fall_speed
	
	
	
	$Sprite2D.set_modulate(Color8(255,255,255))
#endregion

#region juice
func hitstop_manager(time):
	Engine.time_scale = 0
	await get_tree().create_timer(time, true, false, true).timeout
	Engine.time_scale = 1

func knockback(force, time, body, knockback_up: bool = true):
	can_move = false
	can_walk = false
	
	var knockback_dir = (body.global_position - global_position).normalized()
	
	if knockback_dir.x < 0:
		knockback_dir.x = -1
	else:
		knockback_dir.x = 1
	
	forced_move.x = -force * knockback_dir.x
	if knockback_up:
		@warning_ignore("integer_division")
		velocity.y = int(JUMPING_SPEED/2)
	
	$StateChart.send_event("heal_cancel")
	
	await get_tree().create_timer(time).timeout
	
	can_move = true
	can_walk = true

func i_frames(time):
	self.add_to_group("invincible")
	$Sprite2D.set_modulate(Color8(255,0,0))
	
	await get_tree().create_timer(time).timeout
	
	$Sprite2D.set_modulate(Color8(255,255,255))
	self.remove_from_group("invincible")


func attack_speed_buff(mult: float = 2.5, time: float = 2.0):
	attack_cooldown = clamp(attack_cooldown/mult, ATTACK_LINGER, 999999)
	
	await get_tree().create_timer(time).timeout
	
	attack_cooldown *= mult
#endregion

#region mana
func add_mana(add_amount):
	mana_float = clamp(mana_float + add_amount, 0, max_mana)
	mana = int(mana_float)

func _on_mana_set(new_mana):
	mana = clamp(new_mana, 0, max_mana)
	
	player_mana_changed.emit(mana)

func _on_max_mana_set(new_max_mana):
	max_mana = new_max_mana
	
	mana = max_health
	
	player_max_mana_changed.emit()
#endregion
