extends CharacterBody2D

#region setup

@export var stats: Stats

signal killed(node: Node2D)

@export var move_speed: float = 250.0

@export var retreat_speed_mult: float = 0.6

@export var nav_agent: NavigationAgent2D

@onready var state_chart: StateChart = $StateChart
@onready var attack_cooldown: Timer = $"attack cooldown"

@export var attack_count: int = 1

var can_attack: bool = true

var facing_dir: int = -1 # -1 = left           1 = right


const ASPID_ATTACK = preload("uid://c2ur5fk7pwnlj")

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
	
	var current_pos: Vector2 = self.global_transform.origin
	var next_path_pos: Vector2 = nav_agent.get_next_path_position()
	var new_velocity = current_pos.direction_to(next_path_pos)
	nav_agent.velocity = new_velocity
	
	
	if $StateChart/ParallelState/moving/move_towards.active:
		update_target_pos(Global.player.global_transform.origin)
	elif $StateChart/ParallelState/moving/retreat.active:
		var nav_map = nav_agent.get_navigation_map()
		var away_dir = (global_position - Global.player.global_position).normalized()
		var desired_pos = global_position + away_dir * 300.0
		var safe_pos = NavigationServer2D.map_get_closest_point(nav_map, desired_pos)
		update_target_pos(safe_pos)
	
	else:
		stop_movement()


func update_target_pos(target_pos: Vector2):
	nav_agent.target_position = target_pos

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if is_nan(safe_velocity.x) || is_nan(safe_velocity.y):
		velocity = Vector2.ZERO
		return
	
	var moving_speed = move_speed
	if $StateChart/ParallelState/moving/retreat.active:
		moving_speed *= retreat_speed_mult
	velocity = velocity.move_toward(safe_velocity * moving_speed, 12.0)
	move_and_slide()

func stop_movement() -> void:
	nav_agent.target_position = global_position
	nav_agent.velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	move_and_slide()
#endregion

#region basic enemy stuff

func damage(damage_value: int):
	stats.health -= damage_value

func i_frames(time):
	add_to_group("invincible")
	await get_tree().create_timer(time).timeout
	remove_from_group("invincible")


#
#func _on_health_changed(current_health: int, max_health: int):
	#print(str(current_health) + " out of " + str(max_health))

func _on_health_depleted():
	process_mode = Node.PROCESS_MODE_DISABLED
	
	$Sprite2D.process_mode = Node.PROCESS_MODE_ALWAYS
	
	velocity = Vector2.ZERO
	
	$CollisionShape2D.set_deferred("disabled", true)
	attack_cooldown.stop()
	
	play_anim("death", ANIM_PRIORITY.DEATH)
#endregion

#region behaviour
func _on_attack_and_stop_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	state_chart.send_event("stop_move")
	state_chart.send_event("attack")

func _on_attack_and_stop_body_exited(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	state_chart.send_event("move_toward")
	state_chart.send_event("can_not_attack")




func _on_retreat_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	state_chart.send_event("retreat")


func _on_retreat_body_exited(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	state_chart.send_event("stop_move")



func _on_move_towards_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	state_chart.send_event("move_toward")
#endregion


#region attacking
func _on_attacking_state_physics_processing(_delta: float) -> void:
	if !is_processing():
		return
	
	if can_attack:
		can_attack = false
		play_anim("attack", ANIM_PRIORITY.ATTACK)


func _on_attack_cooldown_timeout() -> void:
	can_attack = true


func attack():
	var count := attack_count
	var angle_per_shot := deg_to_rad(20) # angle between each projectile
	
	var base_dir = (Global.player.global_position - global_position).normalized()
	var base_angle = base_dir.angle()

	for i in range(count):
		var projectile = ASPID_ATTACK.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position
		
		var offset_index := i - (count - 1) / 2.0
		var angle = base_angle + offset_index * angle_per_shot
		
		var dir := Vector2.RIGHT.rotated(angle)
		projectile.direction = dir
		projectile.rotation = angle

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
