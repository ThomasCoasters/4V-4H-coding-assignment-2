extends CharacterBody2D

@export var stats: Stats

signal killed(node: Node2D)

@export var move_speed: float = 200.0

@export var nav_agent: NavigationAgent2D

@onready var state_chart: StateChart = $StateChart

func _ready() -> void:
	if stats != null:
		stats = stats.duplicate(true)
	
	stats.health_depleted.connect(_on_health_depleted)

#region pathfinding

func _physics_process(_delta: float) -> void:
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
	velocity = velocity.move_toward(safe_velocity * move_speed, 12.0)
	move_and_slide()

func stop_movement() -> void:
	nav_agent.target_position = global_position
	nav_agent.velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	move_and_slide()
#endregion


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
	killed.emit(self)

#region behaviour
func _on_attack_and_stop_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	state_chart.send_event("stop_move")
	state_chart.send_event("can_attack")

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

#endregion
