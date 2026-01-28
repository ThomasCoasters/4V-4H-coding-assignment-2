extends CharacterBody2D

#region setup

@export var stats: Stats

signal killed(node: Node2D)

@export_group("moving")
@export var move_speed: float = 250.0

@export var retreat_speed_mult: float = 0.6

@export var nav_agent: NavigationAgent2D

@onready var state_chart: StateChart = $StateChart
@onready var attack_cooldown: Timer = $"attack cooldown"

@export_group("attacking")
@export_range(0.0, 5.0, 0.01) var attack_cooldown_time: float = 0.6

@export_range(1, 12, 1) var attack_count: int = 1

@export_range(0, 360, 1, "radians_as_degrees") var shot_angle: int = 20

var can_attack: bool = true

var facing_dir: int = -1 # -1 = left           1 = right


const GRIMMKIN_ATTACK = preload("uid://7s842kuvjrm8")


var current_anim: String

enum ANIM_PRIORITY {
	IDLE,
	TURN,
	ATTACK,
	DEATH
}

var current_anim_priority: int = 0

@export var start_active := true

func _ready() -> void:
	$"attack cooldown".wait_time = attack_cooldown_time
	
	if !start_active:
		deactivate()
	else:
		activate()
	
	
	if stats != null:
		stats = stats.duplicate(true)
	
	stats.health_depleted.connect(_on_health_depleted)
	
	$Sprite2D.animation_finished.connect(_on_animation_finished)



func activate():
	set_process(true)
	set_physics_process(true)
	
	self.remove_from_group("deactive")

func deactivate():
	set_process(false)
	set_physics_process(false)
	
	self.add_to_group("deactive")
	
	if nav_agent:
		nav_agent.velocity = Vector2.ZERO
		nav_agent.target_position = global_position
#endregion

#region pathfinding

func _physics_process(_delta: float) -> void:
	if is_nan(position.x) || is_nan(position.y):
		push_error("Enemy position became NaN")
		killed.emit(self)
		return
	
	
	play_anim("idle", ANIM_PRIORITY.IDLE)
	
	update_facing()
	$Sprite2D.flip_h = facing_dir == 1


func teleport_around_player(
	radius := 400.0,
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
	
	$Sprite2D.process_mode = Node.PROCESS_MODE_ALWAYS
	
	velocity = Vector2.ZERO
	
	$CollisionShape2D.set_deferred("disabled", true)
	attack_cooldown.stop()
	
	play_anim("death", ANIM_PRIORITY.DEATH)
#endregion

#region behaviour
func _on_move_towards_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	state_chart.send_event("active")
#endregion


#region attacking
func _on_attacking_state_entered() -> void:
	play_anim("attack", ANIM_PRIORITY.ATTACK)


func _on_attack_cooldown_timeout() -> void:
	state_chart.send_event("can_not_attack")


func attack():
	var count := attack_count
	var angle_per_shot := deg_to_rad(shot_angle)
	
	var base_dir = (Global.player.global_position - global_position).normalized()
	var base_angle = base_dir.angle()

	for i in range(count):
		var projectile = GRIMMKIN_ATTACK.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position
		
		var offset_index := i - (count - 1) / 2.0
		var angle = base_angle + offset_index * angle_per_shot
		
		var dir := Vector2.RIGHT.rotated(angle)
		projectile.direction = dir
		projectile.rotation = angle

#endregion


#region dashing
func _on_dashing_state_entered() -> void:
	print("des")
	
	await get_tree().create_timer(1).timeout
	state_chart.send_event("can_not_attack")
#endregion

#region animations
func play_anim(anim_name: String = "idle", priority: int = 0):
	if priority < current_anim_priority:
		return
	
	current_anim_priority = priority
	
	
	current_anim = anim_name
	
	$Sprite2D.play(anim_name)

func _on_animation_finished():
	current_anim_priority = 0
	
	if current_anim == "attack":
		attack_cooldown.start()
		attack()
	
	if current_anim == "death":
		killed.emit(self)



func update_facing():
	if current_anim == "attack" || current_anim == "death":
		return
	
	
	var new_dir = sign(Global.player.global_position.x - global_position.x)
	
	# Player exactly on top -> ignore
	if new_dir == 0:
		return
	
	# Only react when direction changes
	if new_dir != facing_dir:
		facing_dir = new_dir
		play_anim("turn", ANIM_PRIORITY.TURN)
#endregion


#region choose_attack
func _on_idle_active_state_entered() -> void:
	teleport_around_player()
	
	if randi_range(0,1) == 0:
		state_chart.send_event("attack")
	else:
		state_chart.send_event("dash")
#endregion
