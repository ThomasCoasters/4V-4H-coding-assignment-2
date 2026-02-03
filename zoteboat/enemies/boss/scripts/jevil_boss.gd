extends CharacterBody2D

#region setup
@export var start_active := true
@export var stats: Stats

signal killed(node: Node2D)

@export var nav_agent: NavigationAgent2D

@onready var state_chart: StateChart = $StateChart
@onready var aspid_attack_cooldown: Timer = $"aspid attack cooldown"


@export_group("aspid attack")
@export_range(0.0, 5.0, 0.01) var aspid_attack_cooldown_time: float = 0.6

@export_range(1, 12, 1) var aspid_attack_count: int = 3

@export_range(0, 360, 1, "radians_as_degrees") var aspid_shot_angle: int = 30

@export_range(1, 10, 1) var aspid_attack_times: int = 3
var aspid_attack_time: int = 0


var can_attack: bool = true

var facing_dir: int = -1 # -1 = left           1 = right


const GRIMMKIN_ATTACK = preload("uid://7s842kuvjrm8")

@onready var sprite_2d: AnimatedSprite2D = $Sprite2D

@export var start_attacking: bool = false

var current_anim: String

enum ANIM_PRIORITY {
	IDLE,
	TURN,
	TP,
	ATTACK,
	DEATH
}

var current_anim_priority: int = 0

@export_group("dashing")
@export var dash_speed := 900.0
@export var dash_max_time := 1.0
@export var dash_overshoot := 340.0
@export var dash_slowdown_distance := 180.0
@export var dash_min_speed := 200.0 

var is_dashing := false
var dash_dir := Vector2.ZERO
var dash_distance_target := 0.0
var dash_travelled := 0.0

@onready var grimmkin_little_attack_01: AudioStreamPlayer = $audio/GrimmkinLittleAttack01
@onready var grimmkin_little_attack_02: AudioStreamPlayer = $audio/GrimmkinLittleAttack02
@onready var grimmkin_little_attack_03: AudioStreamPlayer = $audio/GrimmkinLittleAttack03
@onready var grimmkin_little_attack_04: AudioStreamPlayer = $audio/GrimmkinLittleAttack04
@onready var grimmkin_little_death_01: AudioStreamPlayer = $audio/GrimmkinLittleDeath01
@onready var grimmkin_little_intro_01: AudioStreamPlayer = $audio/GrimmkinLittleIntro01
@onready var grimmkin_big_long_gasp: AudioStreamPlayer = $audio/GrimmkinBigLongGasp

var random_attack_noise: Array[AudioStreamPlayer]

func _ready() -> void:
	aspid_attack_cooldown.wait_time = aspid_attack_cooldown_time
	
	if !start_active:
		deactivate()
	else:
		activate()
	
	
	if stats != null:
		stats = stats.duplicate(true)
	
	stats.health_depleted.connect(_on_health_depleted)
	
	sprite_2d.animation_finished.connect(_on_animation_finished)
	
	random_attack_noise = [grimmkin_little_attack_01, grimmkin_little_attack_02, grimmkin_little_attack_03, grimmkin_little_attack_04, grimmkin_little_intro_01, grimmkin_big_long_gasp]



func activate():
	set_process(true)
	set_physics_process(true)
	
	self.remove_from_group("deactive")
	
	if start_attacking:
		state_chart.send_event("active")

func deactivate():
	set_process(false)
	set_physics_process(false)
	
	self.add_to_group("deactive")
	
	if nav_agent:
		nav_agent.velocity = Vector2.ZERO
		nav_agent.target_position = global_position
#endregion

#region pathfinding

func _physics_process(delta: float) -> void:
	if is_nan(position.x) || is_nan(position.y):
		push_error("Enemy position became NaN")
		killed.emit(self)
		return
	
	if is_dashing:
		var remaining := dash_distance_target - dash_travelled
		
		# calculate speed scale near the end
		var speed := dash_speed
		if remaining < dash_slowdown_distance:
			var t := remaining / dash_slowdown_distance
			t = clamp(t, 0.0, 1.0)
		
			# smoothstep-style easing (very HK-feel)
			t = t * t * (3.0 - 2.0 * t)
			
			speed = lerp(dash_min_speed, dash_speed, t)
			
		var move_step := speed * delta
		velocity = dash_dir * speed
		move_and_slide()
		
		dash_travelled += move_step
		
		if dash_travelled >= dash_distance_target:
			end_dash()
			return
		
		return
	
	
	play_anim("dance(front)", ANIM_PRIORITY.IDLE)
	
	update_facing()
	sprite_2d.flip_h = facing_dir == 1


func teleport_around_player(
	radius := 500.0,
	min_distance := 350.0,
	max_snap_distance := 32.0,
	attempts := 12
	):
	if !is_instance_valid(Global.player):
		return
	
	var nav_map: RID = nav_agent.get_navigation_map()
	
	for i in range(attempts):
		var angle := randf() * TAU
		var dist := randf_range(min_distance, radius)
		var offset := Vector2(cos(angle), sin(angle)) * dist
		var desired_pos = Global.player.global_position + offset
		
		var nav_pos := NavigationServer2D.map_get_closest_point(nav_map, desired_pos)
		
		if nav_pos.distance_to(desired_pos) > max_snap_distance:
			continue
		
		var path := NavigationServer2D.map_get_path(
			nav_map,
			nav_pos,
			Global.player.global_position,
			false
		)
		
		if path.is_empty():
			continue
		
		global_position = nav_pos
		velocity = Vector2.ZERO
		
		nav_agent.velocity = Vector2.ZERO
		nav_agent.target_position = global_position
		
		return


#endregion

#region basic enemy stuff
func damage(damage_value: int):
	stats.health -= damage_value

func i_frames(time):
	add_to_group("invincible")
	await get_tree().create_timer(time).timeout
	remove_from_group("invincible")

func _on_health_depleted():
	process_mode = Node.PROCESS_MODE_DISABLED
	
	sprite_2d.process_mode = Node.PROCESS_MODE_ALWAYS
	
	velocity = Vector2.ZERO
	
	$CollisionShape2D.set_deferred("disabled", true)
	aspid_attack_cooldown.stop()
	
	play_anim("death", ANIM_PRIORITY.DEATH)
#endregion

#region animations/audio
func play_anim(anim_name: String = "idle", priority: int = 0):
	if priority < current_anim_priority:
		return
	
	current_anim_priority = priority
	
	
	current_anim = anim_name
	
	sprite_2d.play(anim_name)


func stop_anim(wanted_anim: String = "idle"):
	if current_anim != wanted_anim:
		return
	
	if current_anim == "wall":
		current_anim = "none"
	
	_on_animation_finished()

func _on_animation_finished():
	current_anim_priority = 0
	
	if current_anim == "death":
		killed.emit(self)
	
	if current_anim == "attack":
		if $StateChart/ParallelState/attack/spinning_circle.active:
			start_dash()


func update_facing():
	if current_anim == "death":
		return
	
	
	var new_dir = sign(Global.player.global_position.x - global_position.x)
	
	if new_dir == 0:
		return
	
	if new_dir != facing_dir:
		facing_dir = new_dir
		#play_anim("turn", ANIM_PRIORITY.TURN)


func play_audio(audio: AudioStreamPlayer):
	if audio != grimmkin_little_death_01 && current_anim == "death":
		return
	
	audio.pitch_scale = randf_range(0.9, 1.1)
	audio.play()
#endregion


#region choose_attack
func _on_idle_active_state_entered() -> void:
	choose_attack()

func choose_attack():
	await get_tree().create_timer(0.3).timeout
	
	if $StateChart/ParallelState/stun/stunned.active:
		return
	
	match randi_range(1, $StateChart/ParallelState/attack.get_child_count()-1):
		1:
			state_chart.send_event("aspid")
		2:
			state_chart.send_event("circle")
		3:
			state_chart.send_event("ducks")
		4:
			state_chart.send_event("scythe")
		5:
			state_chart.send_event("ceiling")
		6:
			state_chart.send_event("homing")
		7:
			state_chart.send_event("head_throw")


func _on_spade_aspid_attack_state_entered() -> void:
	print("aspid")
	state_chart.send_event("attack_stop")

func _on_spinning_circle_state_entered() -> void:
	print("circle")
	play_anim("attack", ANIM_PRIORITY.ATTACK)

func _on_floor_ducks_state_entered() -> void:
	print("ducks")
	state_chart.send_event("attack_stop")

func _on_scythe_state_entered() -> void:
	print("scythe")
	state_chart.send_event("attack_stop")

func _on_ceiling_diamonds_state_entered() -> void:
	print("ceiling")
	state_chart.send_event("attack_stop")

func _on_homing_clover_state_entered() -> void:
	print("homing")
	state_chart.send_event("attack_stop")

func _on_head_throw_state_entered() -> void:
	print("head")
	state_chart.send_event("attack_stop")
#endregion





#region dashing
func start_dash():
	play_anim("dash", ANIM_PRIORITY.ATTACK)
	
	is_dashing = true
	dash_travelled = 0.0
	
	dash_dir = (Global.player.global_position - global_position).normalized()
	
	sprite_2d.flip_h = true
	look_at(Global.player.global_position)
	rotation_degrees += 90
	
	var dist_to_player = global_position.distance_to(Global.player.global_position)
	dash_distance_target = dist_to_player + dash_overshoot
	
	if nav_agent:
		nav_agent.velocity = Vector2.ZERO


func end_dash():
	is_dashing = false
	velocity = Vector2.ZERO
	
	rotation_degrees = 0
	
	state_chart.send_event("attack_stop")
	stop_anim("dash")
#endregion
