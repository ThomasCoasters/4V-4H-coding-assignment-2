extends CharacterBody2D

#region setup
@export_group("setup")
@export var start_active := true
@export var stats: Stats

signal killed(node: Node2D)

@export var nav_agent: NavigationAgent2D


@onready var state_chart: StateChart = $StateChart
@onready var stagger_timer: Timer = $stagger_timer

var arena_bounds: CollisionShape2D

enum ArenaSurface {
	FLOOR_CENTER,
	FLOOR_RANDOM,
	CEILING,
	LEFT_WALL,
	RIGHT_WALL
}

@export_group("phase settings")
@export_subgroup("phase start %")
@export_range(0.0, 1.0, 0.01) var phase_2_health_percent: float = 0.99
@export_range(0.0, 1.0, 0.01) var phase_3_health_percent: float = 0.96
@export_range(0.0, 1.0, 0.01) var anim_tp_time: float = 0.5
@export_range(0.0, 1.0, 0.01) var phase_2_anim_tp_time: float = 0.25
@export_range(0.0, 1.0, 0.01) var phase_3_anim_tp_time: float = 0.7

@export_range(0.0, 5.0, 0.01) var stagger_time: float = 0.5
@export_range(0.0, 5.0, 0.01) var phase_2_stagger_time: float = 0.25
@export_range(0.0, 5.0, 0.01) var phase_3_stagger_time: float = 0.7

@export_range(0, 3, 1) var begin_phase: int = 1

@export_group("attacks (phase 1)")
@export_subgroup("aspid attack")
@export_range(0.0, 5.0, 0.01) var aspid_attack_cooldown_time: float = 0.6
@export_range(1, 12, 1) var aspid_attack_count: int = 3
@export_range(0, 360, 1, "radians_as_degrees") var aspid_shot_angle: int = 30
@export_range(1, 10, 1) var normal_aspid_attack_times: int = 3

var aspid_attack_times: int = 3

const SPADE_ASPID_ATTACK = preload("uid://dsj1u1ifha4x4")


@export_subgroup("dashing")
@export var dash_speed := 900.0
@export var dash_max_time := 1.0
@export var dash_overshoot := 340.0
@export var dash_slowdown_distance := 180.0
@export var dash_min_speed := 200.0 
@export var circle_hearts_attack: Node2D

var is_dashing := false
var dash_dir := Vector2.ZERO
var dash_distance_target := 0.0
var dash_travelled := 0.0

@export_subgroup("duck attack")
@export_range(0.0, 5.0, 0.01) var duck_attack_cooldown_time: float = 0.7
@export var duck_attack_spawner: Node2D

@export_subgroup("scythe attack")
@export_range(0.0, 5.0, 0.01) var scythe_attack_cooldown_time: float = 1.2
@export_range(1, 12, 1) var scythe_attack_count: int = 1
@export_range(0, 360, 1, "radians_as_degrees") var scythe_shot_angle: int = 30
@export_range(1, 10, 1) var normal_scythe_attack_times: int = 1

var scythe_attack_times: int = 1

const SCYTHE_ATTACK = preload("uid://c3jv787661rmy")

@export_subgroup("ceiling attack")
@export_range(0.0, 5.0, 0.01) var ceiling_attack_cooldown_time: float = 0.7
@export_range(0, 50, 1) var ceiling_attack_amount: int = 10
@export_range(0.0, 5.0, 0.01) var ceiling_attack_time_between: float = 0.1
@export_range(0, 5, 1) var ceiling_tp_between_times: int = 2

var ceiling_tp_left: int = 2
const CEILING_DIAMONDS = preload("uid://dr2woxdmhhdi1")

@export_subgroup("homing attack")
@export_range(0.0, 5.0, 0.01) var homing_attack_cooldown_time: float = 0.5
@export_range(1, 12, 1) var homing_attack_count: int = 1
@export_range(0, 360, 1, "radians_as_degrees") var homing_shot_angle: int = 30
@export_range(1, 10, 1) var normal_homing_attack_times: int = 3

var homing_attack_times: int = 3

const HOMING_CLOVER = preload("uid://cnp72gjjkivu2")



@export_group("attacks (phase 2)")
@export_subgroup("aspid attack")
@export_range(0.0, 5.0, 0.01) var phase_2_aspid_attack_cooldown_time: float = 0.6
@export_range(1, 12, 1) var phase_2_aspid_attack_count: int = 3
@export_range(0, 360, 1, "radians_as_degrees") var phase_2_aspid_shot_angle: int = 30
@export_range(1, 10, 1) var phase_2_normal_aspid_attack_times: int = 3


@export_subgroup("dashing")
@export var phase_2_dash_speed := 900.0
@export var phase_2_dash_max_time := 1.0
@export var phase_2_dash_overshoot := 340.0
@export var phase_2_dash_slowdown_distance := 180.0
@export var phase_2_dash_min_speed := 200.0 
@export var phase_2_orbit_radius := 120
@export var phase_2_orbit_speed := 1.5

@export_subgroup("duck attack")
@export_range(0.0, 5.0, 0.01) var phase_2_duck_attack_cooldown_time: float = 0.7
@export_range(0.0, 20.0, 0.1) var phase_2_duck_attack_active_time: float = 12.0
@export_range(0.0, 5.0, 0.1) var phase_2_duck_attack_spawn_cooldown: float = 1.2
@export_range(0, 1000, 1) var phase_2_duck_attack_speed: int = 450
@export_range(0, 1000, 1) var phase_2_duck_attack_vertical_speed: int = 300

@export_subgroup("scythe attack")
@export_range(0.0, 5.0, 0.01) var phase_2_scythe_attack_cooldown_time: float = 1.2
@export_range(1, 12, 1) var phase_2_scythe_attack_count: int = 1
@export_range(0, 360, 1, "radians_as_degrees") var phase_2_scythe_shot_angle: int = 30
@export_range(1, 10, 1) var phase_2_normal_scythe_attack_times: int = 1

@export_subgroup("ceiling attack")
@export_range(0.0, 5.0, 0.01) var phase_2_ceiling_attack_cooldown_time: float = 0.7
@export_range(0, 100, 1) var phase_2_ceiling_attack_amount: int = 10
@export_range(0.0, 5.0, 0.01) var phase_2_ceiling_attack_time_between: float = 0.1
@export_range(0, 5, 1) var phase_2_ceiling_tp_between_times: int = 2

@export_subgroup("homing attack")
@export_range(0.0, 5.0, 0.01) var phase_2_homing_attack_cooldown_time: float = 0.5
@export_range(1, 12, 1) var phase_2_homing_attack_count: int = 1
@export_range(0, 360, 1, "radians_as_degrees") var phase_2_homing_shot_angle: int = 30
@export_range(1, 10, 1) var phase_2_normal_homing_attack_times: int = 3


@export_group("attacks (phase 3)")
@export_subgroup("aspid attack")
@export_range(0.0, 5.0, 0.01) var phase_3_aspid_attack_cooldown_time: float = 0.9
@export_range(1, 12, 1) var phase_3_aspid_attack_count: int = 3
@export_range(0, 360, 1, "radians_as_degrees") var phase_3_aspid_shot_angle: int = 30
@export_range(1, 10, 1) var phase_3_normal_aspid_attack_times: int = 1


@export_subgroup("dashing")
@export var phase_3_dash_speed := 700.0
@export var phase_3_dash_max_time := 1.0
@export var phase_3_dash_overshoot := 340.0
@export var phase_3_dash_slowdown_distance := 180.0
@export var phase_3_dash_min_speed := 200.0 
@export var phase_3_orbit_radius := 120
@export var phase_3_orbit_speed := 1.0

@export_subgroup("duck attack")
@export_range(0.0, 5.0, 0.01) var phase_3_duck_attack_cooldown_time: float = 1.0
@export_range(0.0, 20.0, 0.1) var phase_3_duck_attack_active_time: float = 4.0
@export_range(0.0, 5.0, 0.1) var phase_3_duck_attack_spawn_cooldown: float = 1.5
@export_range(0, 1000, 1) var phase_3_duck_attack_speed: int = 300
@export_range(0, 1000, 1) var phase_3_duck_attack_vertical_speed: int = 200

@export_subgroup("ceiling attack")
@export_range(0.0, 5.0, 0.01) var phase_3_ceiling_attack_cooldown_time: float = 1.0
@export_range(0, 100, 1) var phase_3_ceiling_attack_amount: int = 7
@export_range(0.0, 5.0, 0.01) var phase_3_ceiling_attack_time_between: float = 0.2
@export_range(0, 5, 1) var phase_3_ceiling_tp_between_times: int = 1

@export_subgroup("homing attack")
@export_range(0.0, 5.0, 0.01) var phase_3_homing_attack_cooldown_time: float = 1.0
@export_range(1, 12, 1) var phase_3_homing_attack_count: int = 1
@export_range(0, 360, 1, "radians_as_degrees") var phase_3_homing_shot_angle: int = 30
@export_range(1, 10, 1) var phase_3_normal_homing_attack_times: int = 1


var can_attack: bool = true

var facing_dir: int = -1 # -1 = left           1 = right


@onready var sprite_2d: AnimatedSprite2D = $Sprite2D

var start_attacking: bool = false

var current_anim: String

enum ANIM_PRIORITY {
	IDLE,
	TURN,
	TP,
	ATTACK,
	DEATH
}

var current_anim_priority: int = 0


@onready var grimmkin_little_attack_01: AudioStreamPlayer = $audio/GrimmkinLittleAttack01
@onready var grimmkin_little_attack_02: AudioStreamPlayer = $audio/GrimmkinLittleAttack02
@onready var grimmkin_little_attack_03: AudioStreamPlayer = $audio/GrimmkinLittleAttack03
@onready var grimmkin_little_attack_04: AudioStreamPlayer = $audio/GrimmkinLittleAttack04
@onready var grimmkin_little_death_01: AudioStreamPlayer = $audio/GrimmkinLittleDeath01
@onready var grimmkin_little_intro_01: AudioStreamPlayer = $audio/GrimmkinLittleIntro01
@onready var grimmkin_big_long_gasp: AudioStreamPlayer = $audio/GrimmkinBigLongGasp

var random_attack_noise: Array[AudioStreamPlayer]


@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var last_attack: int

func _ready() -> void:
	if !start_active:
		deactivate()
	else:
		activate()
	
	
	if stats != null:
		stats = stats.duplicate(true)
	
	arena_bounds = Global.map.arena_bounds
	
	duck_attack_spawner.position = get_spawn_position_on_surface(ArenaSurface.FLOOR_CENTER)
	duck_attack_spawner.spawn_offset_x = get_arena_rect().size.x / 2
	duck_attack_spawner.set_as_top_level(true)
	
	stagger_timer.wait_time = stagger_time
	
	stats.health_changed.connect(_on_health_changed)
	stats.health_depleted.connect(_on_health_depleted)
	
	sprite_2d.animation_finished.connect(_on_animation_finished)
	
	circle_hearts_attack.set_circle_attack_enabled(false)
	
	random_attack_noise = [grimmkin_little_attack_01, grimmkin_little_attack_02, grimmkin_little_attack_03, grimmkin_little_attack_04, grimmkin_little_intro_01, grimmkin_big_long_gasp]
	
	print(begin_phase)
	if begin_phase == 2:
		@warning_ignore("narrowing_conversion")
		stats.max_health = stats.max_health * phase_2_health_percent
		_on_phase_2_state_entered()
	
	if begin_phase == 3:
		@warning_ignore("narrowing_conversion")
		stats.max_health = stats.max_health * phase_3_health_percent
		
		phase_3_enter()


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
	if $StateChart/ParallelState/stun/stunned.active:
		return
	
	if is_nan(position.x) || is_nan(position.y):
		push_error("Enemy position became NaN")
		killed.emit(self)
		return
	
	if is_dashing:
		var remaining := dash_distance_target - dash_travelled
		
		var speed := dash_speed
		if remaining < dash_slowdown_distance:
			var t := remaining / dash_slowdown_distance
			t = clamp(t, 0.0, 1.0)
		
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
	min_distance := 400.0,
	max_snap_distance := 64.0,
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

#region attack positioning

func get_arena_rect() -> Rect2:
	var shape := arena_bounds.shape as RectangleShape2D
	var extents = shape.extents
	var top_left = arena_bounds.global_position - extents
	return Rect2(top_left, extents * 2)

func get_spawn_position_on_surface(surface: ArenaSurface, margin := 16.0) -> Vector2:
	var rect := get_arena_rect()
	
	match surface:
		ArenaSurface.FLOOR_CENTER:
			return Vector2(
				rect.get_center().x,
				rect.end.y - margin
			)
		
		ArenaSurface.FLOOR_RANDOM:
			return Vector2(
				randf_range(rect.position.x, rect.end.x),
				rect.end.y - margin
			)
		
		ArenaSurface.CEILING:
			return Vector2(
				randf_range(rect.position.x, rect.end.x),
				rect.position.y + margin
			)
		
		ArenaSurface.LEFT_WALL:
			return Vector2(
				rect.position.x + margin,
				randf_range(rect.position.y, rect.end.y)
			)
		
		ArenaSurface.RIGHT_WALL:
			return Vector2(
				rect.end.x - margin,
				randf_range(rect.position.y, rect.end.y)
			)
	
	return global_position
#endregion

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
	
	play_anim("death", ANIM_PRIORITY.DEATH)

func _on_health_changed(health, max_health):
	if health <= max_health * phase_2_health_percent && begin_phase == 1:
		print("phase 2")
		await get_tree().physics_frame
		state_chart.send_event("phase 2")
	
	if health <= max_health * phase_3_health_percent && begin_phase != 3:
		killed.emit(self)
#endregion

#region animations/audio
func play_anim(anim_name: String = "idle", priority: int = 0):
	if current_anim == "death":
		return
	
	if anim_name == "tp_out":
		teleport(true)
		return
	elif anim_name == "tp_in":
		teleport(false)
		return
	
	
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
		if $StateChart/ParallelState/attack/spade_aspid_attack.active:
			aspid_attack()
		
		if $StateChart/ParallelState/attack/spinning_circle.active:
			start_dash()
		
		if $StateChart/ParallelState/attack/floor_ducks.active:
			duck_attack()
		
		
		if $StateChart/ParallelState/attack/ceiling_diamonds.active:
			ceiling_diamonds_attack()
		
		if $StateChart/ParallelState/attack/homing_clover.active:
			homing_attack()
		
		if begin_phase != 3:
			if $StateChart/ParallelState/attack/scythe.active:
				scythe_attack()

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


func teleport(out: bool = true):
	var to_scale = 1.0
	var from_scale = 0
	if out:
		to_scale = 0
		from_scale = 1.0
	else:
		collision_shape_2d.disabled = true
		if $StateChart/ParallelState/attack/spinning_circle.active:
			circle_hearts_attack.set_circle_attack_enabled(true, anim_tp_time)
	
	
	
	var tween := get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "scale:x", to_scale, anim_tp_time).from(from_scale)
	tween.finished.connect(func():
		if out:
			teleport_around_player()
			play_anim("tp_in")
		else:
			collision_shape_2d.disabled = false
			play_anim("attack", ANIM_PRIORITY.ATTACK)
	)
#endregion




#region choose_attack
func _on_idle_active_state_entered() -> void:
	choose_attack()

func choose_attack():
	await get_tree().create_timer(0.3).timeout
	
	if $StateChart/ParallelState/stun/stunned.active:
		return
	
	var attack_number := last_attack
	var max_attacks := $StateChart/ParallelState/attack.get_child_count() - 1
	
	while attack_number == last_attack and max_attacks > 1:
		attack_number = randi_range(1, max_attacks)
	
	last_attack = attack_number
	
	match attack_number:
		1:
			state_chart.send_event("aspid")
		2:
			state_chart.send_event("circle")
		3:
			state_chart.send_event("ducks")
		4:
			state_chart.send_event("ceiling")
		5:
			state_chart.send_event("homing")
		6:
			state_chart.send_event("scythe")


func _on_spade_aspid_attack_state_entered() -> void:
	print("aspid")
	aspid_attack_times = normal_aspid_attack_times
	play_anim("tp_out")

func _on_spinning_circle_state_entered() -> void:
	print("circle")
	play_anim("tp_out")

func _on_floor_ducks_state_entered() -> void:
	print("ducks")
	play_anim("tp_out")

func _on_scythe_state_entered() -> void:
	print("scythe")
	scythe_attack_times = normal_scythe_attack_times
	play_anim("tp_out")

func _on_ceiling_diamonds_state_entered() -> void:
	print("ceiling")
	ceiling_tp_left = ceiling_tp_between_times
	play_anim("tp_out")

func _on_homing_clover_state_entered() -> void:
	print("homing")
	homing_attack_times = normal_homing_attack_times
	play_anim("tp_out")
#endregion


#region aspid_attack
func aspid_attack():
	var count := aspid_attack_count
	var angle_per_shot := deg_to_rad(aspid_shot_angle)
	
	var base_dir = (Global.player.global_position - global_position).normalized()
	var base_angle = base_dir.angle()

	for i in range(count):
		var projectile = SPADE_ASPID_ATTACK.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position
		
		var offset_index := i - (count - 1) / 2.0
		var angle = base_angle + offset_index * angle_per_shot
		
		var dir := Vector2.RIGHT.rotated(angle)
		projectile.direction = dir
		projectile.rotation = angle
	
	aspid_attack_times -= 1
	if aspid_attack_times <= 0 || $StateChart/ParallelState/stun/stunned.active:
		state_chart.send_event("attack_stop")
	
	else:
		await get_tree().create_timer(aspid_attack_cooldown_time).timeout
		play_anim("tp_out")

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
	circle_hearts_attack.global_rotation = 0
	
	var dist_to_player = global_position.distance_to(Global.player.global_position)
	dash_distance_target = dist_to_player + dash_overshoot
	
	if nav_agent:
		nav_agent.velocity = Vector2.ZERO


func end_dash():
	is_dashing = false
	velocity = Vector2.ZERO
	
	rotation_degrees = 0
	circle_hearts_attack.global_rotation = 0
	circle_hearts_attack.set_circle_attack_enabled(false)
	
	state_chart.send_event("attack_stop")
	stop_anim("dash")
#endregion

#region scythe attack
func scythe_attack():
	if scythe_attack_times <= 0 || $StateChart/ParallelState/stun/stunned.active:
		await get_tree().create_timer(scythe_attack_cooldown_time).timeout
		state_chart.send_event("attack_stop")
		return
	
	var count := scythe_attack_count
	var angle_per_shot := deg_to_rad(scythe_shot_angle)
	
	var base_dir = (Global.player.global_position - global_position).normalized()
	var base_angle = base_dir.angle()
	
	for i in range(count):
		var projectile = SCYTHE_ATTACK.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position
		
		var offset_index := i - (count - 1) / 2.0
		var angle = base_angle + offset_index * angle_per_shot
		
		var dir := Vector2.RIGHT.rotated(angle)
		projectile.direction = dir
		projectile.rotation = angle
	
	scythe_attack_times -= 1
	
	play_anim("tp_out")

#endregion

#region duck_attack
func duck_attack():
	duck_attack_spawner.start_spawning()
	
	await get_tree().create_timer(duck_attack_cooldown_time).timeout
	state_chart.send_event("attack_stop")
	return
#endregion

#region ceiling diamonds
func ceiling_diamonds_attack():
	if ceiling_tp_left <= 0 || $StateChart/ParallelState/stun/stunned.active:
		await get_tree().create_timer(ceiling_attack_cooldown_time).timeout
		state_chart.send_event("attack_stop")
		return
	
	@warning_ignore("integer_division")
	var count = ceiling_attack_amount / ceiling_tp_between_times
	
	for i in range(count):
		var projectile = CEILING_DIAMONDS.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.position = get_spawn_position_on_surface(ArenaSurface.CEILING)
		projectile.position.y -= projectile.top_out_view_px
		projectile.set_as_top_level(true)
		await get_tree().create_timer(ceiling_attack_time_between).timeout
	
	ceiling_tp_left -= 1
	
	play_anim("tp_out")

#endregion

#region homing_attack
func homing_attack():
	var count := homing_attack_count
	var angle_per_shot := deg_to_rad(homing_shot_angle)
	
	var base_dir = (Global.player.global_position - global_position).normalized()
	var base_angle = base_dir.angle()

	for i in range(count):
		var projectile = HOMING_CLOVER.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position
		
		var offset_index := i - (count - 1) / 2.0
		var angle = base_angle + offset_index * angle_per_shot
		
		var dir := Vector2.RIGHT.rotated(angle)
		projectile.direction = dir
		projectile.rotation = angle
	
	homing_attack_times -= 1
	if homing_attack_times <= 0 || $StateChart/ParallelState/stun/stunned.active:
		state_chart.send_event("attack_stop")
	
	else:
		await get_tree().create_timer(aspid_attack_cooldown_time).timeout
		play_anim("tp_out")

#endregion



#region phases
func _on_phase_2_state_entered() -> void:
	anim_tp_time = phase_2_anim_tp_time
	stagger_timer.wait_time = phase_2_stagger_time
	
	aspid_attack_cooldown_time = phase_2_aspid_attack_cooldown_time
	aspid_attack_count = phase_2_aspid_attack_count
	aspid_shot_angle = phase_2_aspid_shot_angle
	normal_aspid_attack_times = phase_2_normal_aspid_attack_times
	
	circle_hearts_attack.orbit_radius = phase_2_orbit_radius
	circle_hearts_attack.orbit_speed = phase_2_orbit_speed
	dash_speed = phase_2_dash_speed
	dash_max_time = phase_2_dash_max_time
	dash_overshoot = phase_2_dash_overshoot
	dash_slowdown_distance = phase_2_dash_slowdown_distance
	dash_min_speed = phase_2_dash_min_speed
	
	duck_attack_cooldown_time = phase_2_duck_attack_cooldown_time
	duck_attack_spawner.active_time = phase_2_duck_attack_active_time
	duck_attack_spawner.spawn_cooldown = phase_2_duck_attack_spawn_cooldown
	duck_attack_spawner.duck_speed = phase_2_duck_attack_speed
	duck_attack_spawner.duck_vertical_speed = phase_2_duck_attack_vertical_speed
	
	
	scythe_attack_cooldown_time = phase_2_scythe_attack_cooldown_time
	scythe_attack_count = phase_2_scythe_attack_count
	scythe_shot_angle = phase_2_scythe_shot_angle
	normal_scythe_attack_times = phase_2_normal_scythe_attack_times
	
	ceiling_attack_cooldown_time = phase_2_ceiling_attack_cooldown_time
	ceiling_attack_amount = phase_2_ceiling_attack_amount
	ceiling_attack_time_between = phase_2_ceiling_attack_time_between
	ceiling_tp_between_times = phase_2_ceiling_tp_between_times
	
	homing_attack_count = phase_2_homing_attack_count
	homing_attack_cooldown_time = phase_2_homing_attack_cooldown_time
	homing_shot_angle = phase_2_homing_shot_angle
	normal_homing_attack_times = phase_2_normal_homing_attack_times

func phase_3_enter():
	$StateChart/ParallelState/attack/scythe.queue_free()
	
	anim_tp_time = phase_3_anim_tp_time
	stagger_timer.wait_time = phase_3_stagger_time
	
	aspid_attack_cooldown_time = phase_3_aspid_attack_cooldown_time
	aspid_attack_count = phase_3_aspid_attack_count
	aspid_shot_angle = phase_3_aspid_shot_angle
	normal_aspid_attack_times = phase_3_normal_aspid_attack_times
	
	circle_hearts_attack.orbit_radius = phase_3_orbit_radius
	circle_hearts_attack.orbit_speed = phase_3_orbit_speed
	dash_speed = phase_3_dash_speed
	dash_max_time = phase_3_dash_max_time
	dash_overshoot = phase_3_dash_overshoot
	dash_slowdown_distance = phase_3_dash_slowdown_distance
	dash_min_speed = phase_3_dash_min_speed
	
	duck_attack_cooldown_time = phase_3_duck_attack_cooldown_time
	duck_attack_spawner.active_time = phase_3_duck_attack_active_time
	duck_attack_spawner.spawn_cooldown = phase_3_duck_attack_spawn_cooldown
	duck_attack_spawner.duck_speed = phase_3_duck_attack_speed
	duck_attack_spawner.duck_vertical_speed = phase_3_duck_attack_vertical_speed
	
	ceiling_attack_cooldown_time = phase_3_ceiling_attack_cooldown_time
	ceiling_attack_amount = phase_3_ceiling_attack_amount
	ceiling_attack_time_between = phase_3_ceiling_attack_time_between
	ceiling_tp_between_times = phase_3_ceiling_tp_between_times
	
	homing_attack_count = phase_3_homing_attack_count
	homing_attack_cooldown_time = phase_3_homing_attack_cooldown_time
	homing_shot_angle = phase_3_homing_shot_angle
	normal_homing_attack_times = phase_3_normal_homing_attack_times
#endregion


#region stagger
func _on_stagger_timer_timeout() -> void:
	state_chart.send_event("stop_stun")
	choose_attack()

func _on_stunned_state_entered() -> void:
	play_anim("stagger")

#endregion
