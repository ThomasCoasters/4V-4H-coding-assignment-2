extends CharacterBody2D
class_name Player


#region vars setup

@export_group("cheaty ability unlocks", "has_")
@export var has_dash: bool
@export var has_wall_cling: bool
@export var has_double_jump: bool


@export_group("QoL changes")
@export_range(0.0, 1.0, 0.01) var controller_rumble_mult: float = 1.0
@export_range(0.0, 1.0, 0.01) var screen_shake_mult: float = 1.0


const GRAVITY : int = 12

var gravity_multiplier := 0.0


var is_jumping = false
var jump_timer := Timer.new()
const MAX_JUMP_TIME : float = 0.3
const JUMPING_SPEED : int = -750
var max_jumps_amount : int = 1
var jumps_amount : int = max_jumps_amount
var jump_max_held: bool = false

var max_fall_speed : int = 1200
var normal_max_fall_speed: int = max_fall_speed

var direction := Vector2(0,0)
var last_direction := Vector2(1,0)
const MOVE_SPEED : int = 400

@export_group("nodes")
@export var Camera : Camera2D
const LOOKAHEAD : int = 50
var current_camera_type := "free" #"free" or "locked" or "lock_x" or "lock_y"
var forced_position = null
const LOOKAHEAD_COOLDOWN : float = 0.4
var look_timer: SceneTreeTimer = null

var attack_cooldown : float = 0.41
const ATTACK_LINGER : float = 0.15
const ATTACK_ANIM_LINGER: float = 0.2

const NORMAL_ATTACK = preload("res://assets/player/attacks/normal/normal attack.tscn")
const UP_ATTACK = preload("res://assets/player/attacks/up_attack/up attack.tscn")
const DOWN_ATTACK = preload("res://assets/player/attacks/pogo/pogo.tscn")
const ZOTE_SHELL = preload("uid://bfxn25erf4tm3")
var death_shell: Node = null

var can_attack : bool = true
var can_move : bool = true
var can_walk : bool = true

const HARDFALL_STUN_TIME : float = 0.6

var forced_move : Vector2

@export_group("attack")
@export var attack_damage : int = 5

@export_group("health and mana")
@export var max_health : int = 5: set = _on_max_health_set
var health : int: set = _on_health_set
signal player_health_changed(health: int)
signal player_max_health_changed()
@onready var heal_idle: AtomicState = $StateChart/ParallelState/healing/Idle


var i_frames_hit_time: float = 1.2
var hitstun_time: float = 0.25
var hitstop_time: float = 0.075
var iframe_tween: Tween
var iframe_counter: int = 0

const GET_HIT_KNOCKBACK_FORCE = 450
const GET_HIT_KNOCKBACK_TIME = 0.15

const ATTACK_KNOCKBACK_FORCE = 300
const ATTACK_KNOCKBACK_TIME = 0.05


@export var mana_per_attack: int = 11
@export var max_mana : int = 99: set = _on_max_mana_set
var mana : int : set = _on_mana_set
signal player_mana_changed(mana: int)
signal player_max_mana_changed()

var mana_to_heal : int = 33
var heal_time : float = 1.2

var heal_time_expired: float = 0

var mana_float = float(mana)

@export var heal_health: int = 1

var healing_max_fall_speed_multiplier: int = 6

var dash_force:int = 1000
var dash_time:float = 0.3


@onready var state_chart: StateChart = $StateChart
@onready var moving: AtomicState = $StateChart/ParallelState/moving/Moving

var current_anim: String

enum ANIM_PRIORITY {
	IDLE_START,
	IDLE,
	WALK,
	FALL,
	STAND,
	JUMP,
	DASH,
	ATTACK,
	WALL,
	HARDFALL_LAND,
	HEAL,
	DEATH
}

var current_anim_priority: int = 0

var roar_timer := Timer.new()
const ROAR_START_TIMER: float = 1.0

var collision_size

var facing_dir: int = 1 # -1 = left           1 = right

const HIT_EFFECT = preload("uid://ear4rb07owa4")
const HEAL_EFFECT = preload("uid://bk06i67jmxte2")

var oneshot_loaded_particles := []

signal jumping()

var hazard_respawn_location: Vector2

@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var ui_holder: CanvasLayer = $UiHolder

var unkillable: bool = false



@onready var hornet_needle_catch: AudioStreamPlayer = $audio/HornetNeedleCatch

@onready var zote_battle_death: AudioStreamPlayer = $audio/death/ZoteBattleDeath

@onready var focus_health_heal: AudioStreamPlayer = $audio/health/FocusHealthHeal
@onready var hero_damage: AudioStreamPlayer = $audio/health/HeroDamage
@onready var hero_double_damage: AudioStreamPlayer = $audio/health/HeroDoubleDamage

@onready var hero_jump: AudioStreamPlayer = $audio/moving/HeroJump
@onready var zote_land: AudioStreamPlayer = $audio/moving/ZoteLand
@onready var zote_battle_fall_01: AudioStreamPlayer = $audio/moving/ZoteBattleFall01
@onready var hero_land_hard: AudioStreamPlayer = $audio/moving/HeroLandHard
@onready var zote_get_up: AudioStreamPlayer = $audio/moving/ZoteGetUp
@onready var hero_run_footsteps_stone: AudioStreamPlayer = $audio/moving/HeroRunFootstepsStone
@onready var hero_wall_jump: AudioStreamPlayer = $audio/moving/HeroWallJump
@onready var hero_wall_slide: AudioStreamPlayer = $audio/moving/HeroWallSlide
@onready var hero_falling: AudioStreamPlayer = $audio/moving/HeroFalling

@onready var zote_01: AudioStreamPlayer = $audio/talking_noises/Zote01
@onready var zote_02: AudioStreamPlayer = $audio/talking_noises/Zote02
@onready var zote_03_030084: AudioStreamPlayer = $"audio/talking_noises/Zote03#030084"
@onready var zote_03: AudioStreamPlayer = $audio/talking_noises/Zote03
@onready var zote_04: AudioStreamPlayer = $audio/talking_noises/Zote04
@onready var zote_05: AudioStreamPlayer = $audio/talking_noises/Zote05
var talking_noises: Array[AudioStreamPlayer]

@onready var sword_1: AudioStreamPlayer = $audio/sword/Sword1
@onready var sword_2: AudioStreamPlayer = $audio/sword/Sword2
@onready var sword_3: AudioStreamPlayer = $audio/sword/Sword3
@onready var sword_4: AudioStreamPlayer = $audio/sword/Sword4
@onready var enemy_damage: AudioStreamPlayer = $audio/sword/EnemyDamage
var sword_noises: Array[AudioStreamPlayer]

@onready var zote_final_town_loop: AudioStreamPlayer = $audio/talking_noises/ZoteFinalTownLoop


var save_pos: Vector2
#endregion

#region setup/process

func _ready() -> void:
	Global.player = self
	setup()
	
	hazard_respawn_location = global_position
	
	sprite_2d.animation_finished.connect(_on_animation_finished)
	
	
	
	talking_noises = [zote_01, zote_02, zote_03_030084, zote_03, zote_04, zote_05]
	sword_noises = [sword_1, sword_2, sword_3, sword_4]

func setup():
	max_health = SaveLoad.contents_to_save.max_health
	
	if !has_dash:
		has_dash = SaveLoad.contents_to_save.has_dash
	if !has_wall_cling:
		has_wall_cling = SaveLoad.contents_to_save.has_wall_cling
	if !has_double_jump:
		has_double_jump = SaveLoad.contents_to_save.has_double_jump
	
	#region timers setup
	jump_timer.wait_time = MAX_JUMP_TIME
	jump_timer.one_shot = true
	jump_timer.timeout.connect(_on_jump_timer_timeout)
	add_child(jump_timer)
	
	roar_timer.wait_time = ROAR_START_TIMER
	roar_timer.one_shot = true
	roar_timer.timeout.connect(_on_roar_timer_timeout)
	add_child(roar_timer)
	#endregion
	health = max_health
	
	collision_size = $CollisionShape2D.shape.size

func _physics_process(_delta: float) -> void:
	#region jumping/falling
	var last_vertical_velocity = velocity.y
	
	velocity.y += GRAVITY*gravity_multiplier
	
	velocity.y = clamp(velocity.y, JUMPING_SPEED, max_fall_speed)
	
	if $StateChart/ParallelState/Jumping/falling.active:
		play_anim("fall", ANIM_PRIORITY.FALL)
	
	if $StateChart/ParallelState/moving/Moving.active:
		play_anim("walk", ANIM_PRIORITY.WALK)
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
	for area in $Area2D.get_overlapping_areas():
		_on_player_entered(area)
	
	if velocity.y == 0:
		stop_anim("fall")
	
	if velocity == Vector2.ZERO:
		stop_anim("walk")
		play_anim("he_just_standing_there__menacingly", ANIM_PRIORITY.IDLE_START)
		if roar_timer.is_stopped():
			roar_timer.start()
	else:
		zote_final_town_loop.stop()
		roar_timer.stop()
	
	
	update_facing()
	
	sprite_2d.flip_h = facing_dir == -1


func _process(_delta: float) -> void:
	
	#region state machine events
		#region inputs
	
	if Input.is_action_just_pressed("jump"):
		state_chart.set_expression_property("jumps_amount", jumps_amount)
		state_chart.send_event("jump_clicked")
	
	if Input.is_action_just_released("jump"):
		state_chart.send_event("jump_released")
	
	if Input.is_action_just_pressed("left") || Input.is_action_just_pressed("right"):
		state_chart.send_event("moving_clicked")
	
	if !Input.is_action_pressed("left") && !Input.is_action_pressed("right"):
		state_chart.send_event("moving_released")
	
	if Input.is_action_just_pressed("attack") && can_attack:
		state_chart.send_event("attack_start")
	
	
	if Input.is_action_just_pressed("heal") && can_move:
		if $StateChart/ParallelState/attacking/Idle.active && mana >= mana_to_heal:
			state_chart.send_event("heal_start")
	
	if Input.is_action_just_released("heal") && heal_time_expired <= heal_time - 0.2:
		state_chart.send_event("heal_cancel")
	
	if Input.is_action_just_pressed("dash") && can_move && !is_on_wall_only() && has_dash:
		state_chart.send_event("dash_start")
	
	
	if Input.is_action_just_pressed("pause"):
		zote_final_town_loop.stop()
		Global.map_holder.change_gui_scene("res://assets/pause_screen/pause_screen.tscn")
	#endregion
		#region checks
	
	if is_on_floor():
		state_chart.send_event("on_ground")
		state_chart.send_event("dash_rechagering")
	if is_on_ceiling():
		state_chart.send_event("jump_released")
	
	if is_on_wall_only() && velocity.y >0 && has_wall_cling:
		state_chart.send_event("on_wall")
		state_chart.send_event("dash_recharged")
	
	if !is_jumping && !is_on_floor():
		state_chart.send_event("fell_of_platform")
	
	if !is_on_wall() || (is_on_wall() && !test_move(transform, direction)):
		state_chart.send_event("fell_of_wall")
	#endregion
	#endregion
	
	
	camera_movement()
	
	
	#region direction inputs
	direction = Vector2(0,0)
	
	if !can_move:
		return
	
	direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("up") - Input.get_action_strength("down")
	).limit_length(1.0)
	
	if Input.get_action_strength("left") >= 0.5 || Input.get_action_strength("right") >= 0.5:
		direction.x = sign(direction.x)
	
	if Input.get_action_strength("up") >= 0.2 || Input.get_action_strength("down") >= 0.2:
		direction.y = sign(direction.y)
	else:
		direction.y = 0
	
	if direction.x != 0:
		last_direction.x = direction.x
	
	#endregion
	

#endregion



#region jumping/falling/on_ground
func _on_jump_timer_timeout() -> void:
	jump_max_held = true
	state_chart.send_event("jump_released")


func _on_jump_state_entered() -> void:
	if is_jumping || !can_move || (is_on_wall_only() && velocity.y < 0):
		return
	
	play_anim("jump", ANIM_PRIORITY.JUMP)
	play_audio(hero_jump)
	
	jumping.emit()
	
	velocity.y = JUMPING_SPEED
	is_jumping = true
	
	jump_timer.start()
	
	gravity_multiplier = 1
	
	jump_max_held = false
	
	#current_camera_type = "locked"


func _on_falling_state_entered() -> void:
	jumps_amount -= 1
	
	jump_timer.stop()
	
	if is_jumping && !jump_max_held:
		velocity.y /= 2
	
	is_jumping = false
	
	gravity_multiplier = 3


func _on_on_ground_state_entered() -> void:
	if has_double_jump:
		max_jumps_amount = 2
	else:
		max_jumps_amount = 1
	
	jumps_amount = max_jumps_amount
	
	#current_camera_type = "free"


func _on_landed(speed):
	if $StateChart/ParallelState/Jumping/hardfall.active && speed >= max_fall_speed && !$StateChart/ParallelState/dash/dashing.active && !$"StateChart/ParallelState/healing/heal start".active:
		play_anim("hardfall_land", ANIM_PRIORITY.HARDFALL_LAND)
		play_audio(hero_land_hard)
		
		can_move = false
		
		vibrate(HARDFALL_STUN_TIME, "hard")
		await get_tree().create_timer(HARDFALL_STUN_TIME).timeout
		
		can_move = true
	
	else:
		play_anim("stand_up", ANIM_PRIORITY.STAND)

func _on_wall_slide_state_entered() -> void:
	var wall_dir = get_wall_direction()  # -1 = left wall, 1 = right wall
	
	play_anim("wall", ANIM_PRIORITY.WALL)
	play_audio(hero_wall_slide)
	
	sprite_2d.position = Vector2(-19 * wall_dir, 5)
	sprite_2d.flip_h = wall_dir == -1
	
	velocity.y = 0
	gravity_multiplier = 0.1
	jumps_amount = max_jumps_amount
	max_fall_speed /= 5

func _on_wall_slide_state_exited() -> void:
	stop_anim("wall")
	hero_wall_slide.stop()
	
	var wall_dir = get_wall_direction()
	position.x -= wall_dir
	
	max_fall_speed *= 5

func _on_to_jumping_form_wall_taken() -> void:
	var dir = sign(last_direction.x)
	play_audio(hero_wall_jump)
	
	forced_move.x = -dir * 500
	
	can_walk = false
	
	await get_tree().create_timer(MAX_JUMP_TIME/2).timeout
	
	forced_move.x = 0
	
	can_walk = true

#endregion

#region camera
func camera_movement():
	if current_camera_type == "locked":
		Camera.set_as_top_level(true)
		if forced_position != null:
			Camera.global_position = forced_position
		return
	
	Camera.set_as_top_level(false)
	
	if current_camera_type == "lock_y" and forced_position != null:
		Camera.global_position.y = forced_position.y
	else:
		camera_movement_y()
	
	if current_camera_type == "lock_x" and forced_position != null:
		Camera.global_position.x = forced_position.x
		return
	
	var dir = sign(last_direction.x)
	Camera.position.x = lerp(
		Camera.position.x,
		dir * LOOKAHEAD,
		0.15
	)

func camera_movement_y():
	if !is_on_floor() || $StateChart/ParallelState/moving/Moving.active:
		Camera.position.y = 0
		Camera.drag_top_margin = 0.25
		look_timer = null        # cancel pending look
		return
	
	Camera.drag_top_margin = 0
	
	var dir_y = direction.y
	
	if dir_y == 0:
		Camera.position.y = 0
		look_timer = null
		return
	
	var target = -dir_y * (LOOKAHEAD * 5 if dir_y == 1 else LOOKAHEAD * 8)
	if Camera.position.y == target:
		return
	
	if look_timer == null:
		look_timer = get_tree().create_timer(LOOKAHEAD_COOLDOWN)
		await look_timer.timeout
		
		# After waiting, check player still holding same direction
		if direction.y == dir_y:
			Camera.position.y = target
		
		look_timer = null
#endregion

#region attacking
func _on_attacking_state_entered() -> void:
	if !can_move:
		state_chart.send_event("attack_stop")
		return
	var dir = sign(direction)
	
	if dir.y == 1:
		start_UP_ATTACK()
	elif dir.y == -1 && !is_on_floor() && !$StateChart/ParallelState/Jumping/wall_slide.active:
		start_DOWN_ATTACK()
	else:
		start_NORMAL_ATTACK()
	
	play_audio(sword_noises[randi_range(0, sword_noises.size()-1)])
	
	await get_tree().create_timer(attack_cooldown).timeout
	
	state_chart.send_event("attack_stop")

func delete_attack() -> void:
	for attack in get_tree().get_nodes_in_group("attacks"):
		attack.queue_free()


func start_UP_ATTACK():
	var attack = UP_ATTACK.instantiate()
	var dir = sign(last_direction.x)
	
	attack.position.y = -50
	attack.scale.x = dir
	
	attack.add_to_group("attacks")
	attack.body_entered.connect(_on_attack_entered)
	
	self.add_child(attack)
	
	play_anim("attack", ANIM_PRIORITY.ATTACK)
	await get_tree().create_timer(ATTACK_LINGER).timeout
	
	delete_attack()
	
	await get_tree().create_timer(ATTACK_ANIM_LINGER).timeout
	
	stop_anim("attack")


func start_DOWN_ATTACK():
	var attack = DOWN_ATTACK.instantiate()
	var dir = sign(last_direction.x)
	
	attack.position = position
	attack.scale.x = dir
	attack.scale.y = -1
	
	attack.add_to_group("attacks")
	attack.body_entered.connect(_on_attack_entered)
	
	Global.map_holder.add_child(attack)
	
	attack.pogo_returned.connect(_on_pogo_returned)
	
	velocity.y = JUMPING_SPEED
	
	can_attack = false

func start_NORMAL_ATTACK():
	var attack = NORMAL_ATTACK.instantiate()
	var dir = sign(last_direction.x)
	
	if !$StateChart/ParallelState/Jumping/wall_slide.active:
		attack.position.x = dir * 15
		attack.scale.x = dir
	else:
		attack.position.x = -dir * 15
		attack.scale.x = -dir
	
	attack.position.y = -10
	
	attack.add_to_group("attacks")
	attack.body_entered.connect(_on_attack_entered)
	
	self.add_child(attack)
	play_anim("attack", ANIM_PRIORITY.ATTACK)
	
	await get_tree().create_timer(ATTACK_LINGER).timeout
	
	delete_attack()
	
	await get_tree().create_timer(ATTACK_ANIM_LINGER).timeout
	
	stop_anim("attack")


func _on_pogo_returned():
	delete_attack()
	
	can_attack = true
	
	play_audio(hornet_needle_catch)


func _on_attack_entered(body: Node2D):
	if !body.is_in_group("enemy") || body.is_in_group("invincible") || body.is_in_group("deactive"):
		return
	
	body.i_frames(ATTACK_LINGER)
	body.damage(attack_damage)
	
	play_audio(enemy_damage)
	
	add_mana(mana_per_attack)
	
	knockback(ATTACK_KNOCKBACK_FORCE, ATTACK_KNOCKBACK_TIME, body, false)
	
	hitstop_manager(hitstop_time, 3, "soft")
	
	display_particle(HIT_EFFECT, body.global_position, Vector2(body.global_position - global_position).normalized())

#endregion

#region HP
func change_health(amount: int, type: String = "normal"):
	if type == "max":
		max_health += amount
		SaveLoad.contents_to_save.max_health = max_health
		SaveLoad._save()
	else:
		health += amount
		
		if amount == -1:
			play_audio(hero_damage)
			play_audio(zote_battle_fall_01)
		elif amount <= -2:
			play_audio(hero_double_damage)
			play_audio(zote_battle_fall_01)


func _on_player_entered(body: Node2D):
	if self.is_in_group("invincible") || body.is_in_group("deactive"):
		return
	
	if (body.is_in_group("enemy") || body.is_in_group("enemy_attack")):
		change_health(-body.stats.attack_damage)
		
		i_frames(i_frames_hit_time)
		
		knockback(GET_HIT_KNOCKBACK_FORCE, GET_HIT_KNOCKBACK_TIME, body, true)
		
		await hitstop_manager(hitstun_time, 1.3, "hard")

func _on_health_set(new_health):
	health = clamp(new_health, 0, max_health)
	
	if health == 0:
		death()
	
	player_health_changed.emit(health)

func _on_max_health_set(new_max_health):
	max_health = new_max_health
	
	health = max_health
	
	player_max_health_changed.emit()

func _on_heal_start_state_physics_processing(delta: float) -> void:
	add_mana(-mana_to_heal * (delta/heal_time))
	
	heal_time_expired += delta
	
	if heal_time_expired >= heal_time-delta:
		state_chart.send_event("heal_finished")

func _on_heal_start_state_entered() -> void:
	display_particle(HEAL_EFFECT, global_position)
	
	play_anim("roar_start", ANIM_PRIORITY.HEAL)
	
	heal_time_expired = 0
	
	can_move = false
	
	max_fall_speed /= healing_max_fall_speed_multiplier
	velocity.y = 50
	
	
	vibrate(heal_time, "extremely soft")

func _on_heal_finished_state_entered() -> void:
	change_health(heal_health)
	
	play_audio(focus_health_heal)
	
	attack_speed_buff()
	
	can_move = true
	
	if Input.is_action_pressed("heal") && $StateChart/ParallelState/attacking/Idle.active && mana >= mana_to_heal && can_move && health != max_health:
		state_chart.send_event("heal_start")

func _on_idle_state_entered() -> void:
	can_move = true
	max_fall_speed = normal_max_fall_speed
	
	stop_anim("roar_start")
	stop_anim("roar_loop")
	stop_vibrate()


func death():
	if unkillable || Global.map_holder.is_transition:
		return
	
	play_audio(zote_battle_death)
	
	death_shell = ZOTE_SHELL.instantiate()
	death_shell.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", death_shell)
	
	Global.map_holder.record_player_death(global_position)
	
	
	current_camera_type = "free"
	forced_position = null
	Camera.set_as_top_level(false)
	Camera.position = Vector2.ZERO
	Camera.position_smoothing_enabled = false
	
	Global.map_holder.respawnable_enemies = {}
	
	SaveLoad._load()
	var room = SaveLoad.contents_to_save.starting_room
	var location = SaveLoad.contents_to_save.starting_location
	
	add_to_group("invincible")
	process_mode = Node.PROCESS_MODE_DISABLED
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	sprite_2d.visible = false
	
	await get_tree().create_timer(1.5).timeout
	
	health = max_health
	
	Global.map_holder.change_2d_scene(room, location)
#endregion

#region juice
func hitstop_manager(time, vibration_time_mult: float = 1.0, vibration_type: String = "off"):
	Engine.time_scale = 0.0001
	
	vibrate(time*vibration_time_mult, vibration_type)
	
	await get_tree().create_timer(time, true, false, true).timeout
	
	Engine.time_scale = 1


func vibrate(time, vibration_type: String = "off"):
	var soft_vibration_amount := 0.0
	var hard_vibration_amount := 0.0
	
	match vibration_type:
		"extremely soft":
			soft_vibration_amount = 0.5
		"soft":
			soft_vibration_amount = 1.0
		"mid-soft":
			soft_vibration_amount = 0.75
			hard_vibration_amount = 0.25
		"medium":
			soft_vibration_amount = 0.5
			hard_vibration_amount = 0.5
		"hard":
			hard_vibration_amount = 1.0
	
	Input.start_joy_vibration(0, soft_vibration_amount * controller_rumble_mult, hard_vibration_amount * controller_rumble_mult, time)
	
	Camera.screen_shake(((soft_vibration_amount*6)+(hard_vibration_amount*14)) * screen_shake_mult, time)

func stop_vibrate():
	Input.stop_joy_vibration(0)
	Camera.stop_shake()



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
	
	state_chart.send_event("heal_cancel")
	
	await get_tree().create_timer(time).timeout
	
	can_move = true
	can_walk = true

func i_frames(time):
	iframe_counter += 1
	var my_id = iframe_counter
	
	add_to_group("invincible")
	
	if iframe_tween:
		iframe_tween.kill()
	
	iframe_tween = create_tween()
	iframe_tween.set_loops()
	iframe_tween.tween_property(sprite_2d, "modulate:a", 0.25, time / 10)
	iframe_tween.tween_property(sprite_2d, "modulate:a", 1.0,  time / 10)
	
	vignette_shrink(0.0, 0.8, time / 6)
	await get_tree().create_timer(time / 6 * 2).timeout
	
	if my_id != iframe_counter:
		return
	
	vignette_return(0.9, 1.3, time / 6 * 4)
	
	await get_tree().create_timer(time).timeout
	
	if my_id != iframe_counter:
		return
	
	
	if iframe_tween:
		iframe_tween.kill()
	
	sprite_2d.modulate.a = 1.0
	remove_from_group("invincible")




func attack_speed_buff(mult: float = 1.5, time: float = 2.0):
	attack_cooldown /= mult
	
	await get_tree().create_timer(time).timeout
	
	attack_cooldown *= mult


func display_particle(particle_scene: PackedScene, pos: Vector2, dir: Vector2 = Vector2(0,0)):
	var particle = particle_scene.instantiate()
	
	get_tree().current_scene.call_deferred("add_child", particle)
	particle.global_position = pos
	
	particle.rotation = dir.angle()
	
	if particle.one_shot:
		particle.emitting = true
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
	
	mana = max_mana
	
	player_max_mana_changed.emit()
#endregion

#region dashing

func _on_dashing_state_entered() -> void:
	can_move = false
	can_walk = false
	
	forced_move.x = facing_dir * dash_force
	
	play_anim("dash_start", ANIM_PRIORITY.DASH)
	
	await get_tree().create_timer(dash_time).timeout
	
	if is_on_floor():
		stop_anim("dash_start")
		play_anim("stand_up", ANIM_PRIORITY.STAND)
	
	can_move = true
	can_walk = true
	
	state_chart.send_event("dash_finished")
#endregion

#region animations

func play_anim(anim_name: String = "idle", priority: int = 0):
	if priority < current_anim_priority:
		return
	
	var last_frame := 0
	var last_frame_progress := 0.0
	
	#region anim specific
	if !is_on_floor():
		$CollisionShape2D.shape.size.y = 24
		$Area2D/CollisionShape2D.shape.size.y = 24
		
		$CollisionShape2D.position.y = (collision_size.y-24)/2
		$Area2D/CollisionShape2D.position.y = (collision_size.y-24)/2
		
		sprite_2d.position.y = -10
	else:
		$CollisionShape2D.shape.size.y = collision_size.y
		$Area2D/CollisionShape2D.shape.size.y = collision_size.y
		
		$CollisionShape2D.position.y = 4.5
		$Area2D/CollisionShape2D.position.y = 4.5
		
		sprite_2d.position.y = -25
	
	if anim_name == "wall":
		sprite_2d.position = Vector2(-19 * sign(last_direction.x), 5)
	elif anim_name == "attack":
		sprite_2d.position = Vector2(20 * sign(last_direction.x), -25)
	else:
		sprite_2d.position = Vector2(0, -25)
	
	if current_anim == "walk":
		last_frame = sprite_2d.frame
		last_frame_progress = sprite_2d.frame_progress
	
	
	if current_anim == "idle" && anim_name != "idle":
		zote_final_town_loop.stop()
	#endregion
	
	current_anim_priority = priority
	
	
	current_anim = anim_name
	
	sprite_2d.play(anim_name)
	
	
	
	if anim_name == "attack":
		sprite_2d.frame = min(
			last_frame,
			sprite_2d.sprite_frames.get_frame_count("attack") - 1
		)
		sprite_2d.frame_progress = last_frame_progress

func stop_anim(wanted_anim: String = "idle"):
	if current_anim != wanted_anim:
		return
	
	if current_anim == "wall":
		current_anim = "none"
	
	_on_animation_finished()


func _on_animation_finished():
	current_anim_priority = 0
	
	if current_anim == "roar_start":
		play_anim("roar_loop", ANIM_PRIORITY.HEAL)
	
	if current_anim == "jump":
		play_anim("fall", ANIM_PRIORITY.FALL)
	
	if current_anim == "hardfall_land":
		play_anim("stand_up", ANIM_PRIORITY.FALL)
	
	if current_anim == "wall":
		current_anim_priority = ANIM_PRIORITY.WALL
	


func _on_roar_timer_timeout():
	play_anim("idle", ANIM_PRIORITY.IDLE)
	
	if !zote_final_town_loop.playing:
		play_audio(zote_final_town_loop)


func update_facing():
	if !can_move:
		return
	
	if Input.is_action_pressed("left"):
		facing_dir = -1
	elif Input.is_action_pressed("right"):
		facing_dir = 1


func get_wall_direction() -> int:
	if is_on_wall():
		var wall_dir = 0
		if test_move(global_transform, Vector2(-1, 0)):
			wall_dir = -1
		elif test_move(global_transform, Vector2(1, 0)):
			wall_dir = 1
		return wall_dir
	return sign(last_direction.x)
#endregion

#region vignette

func vignette_shrink(target_inner: float = 0.2, target_outer: float = 0.5, duration: float = 0.3):
	var mat = Global.vignette.material as ShaderMaterial
	if mat == null:
		return
	
	var tween = create_tween()
	tween.tween_property(mat, "shader_parameter/inner_radius", target_inner, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(mat, "shader_parameter/outer_radius", target_outer, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.play()


func vignette_return(target_inner: float = 1.0, target_outer: float = 1.0, duration: float = 0.3):
	var mat = Global.vignette.material as ShaderMaterial
	if mat == null:
		return
	
	var tween = create_tween()
	tween.tween_property(mat, "shader_parameter/inner_radius", target_inner, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(mat, "shader_parameter/outer_radius", target_outer, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.play()

#endregion

#region hazards
func on_spikes_entered(damage):
	change_health(-damage)
	
	if health <= 0 && !unkillable:
		return
	
	await hitstop_manager(hitstun_time, 1.3, "hard")
	
	fading()
	
	await transition.on_transition_finished
	
	global_position = hazard_respawn_location
	
	await transition.on_transition_finished
	
	can_move = true
	remove_from_group("invincible")
	set_process_mode(Node.PROCESS_MODE_INHERIT)
	Camera.set_process_mode(Node.PROCESS_MODE_INHERIT)
	i_frames(i_frames_hit_time*1.5)
	
	await get_tree().physics_frame
	get_tree().call_group("map_transitions", "set_deferred", "monitoring", true)
	await get_tree().physics_frame
	
	Global.map_holder.is_transition = false


func fading():
	Global.map_holder.is_transition = true
	
	transition.transition()
	can_move = false
	add_to_group("invincible")
	set_process_mode(Node.PROCESS_MODE_DISABLED)
	Camera.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	
	get_tree().call_group("map_transitions", "set_deferred", "monitoring", false)




func set_hazard_respawn():
	hazard_respawn_location = global_position
#endregion

#region audio
func play_audio(audio: AudioStreamPlayer):
	audio.pitch_scale = randf_range(0.9, 1.1)
	audio.play()
#endregion
