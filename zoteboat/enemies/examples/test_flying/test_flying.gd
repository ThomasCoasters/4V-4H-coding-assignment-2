extends CharacterBody2D

@export var stats: Stats

signal killed(node: Node2D)

@export var move_speed: float = 200.0

@export var nav_agent: NavigationAgent2D

func _ready() -> void:
	if stats != null:
		stats = stats.duplicate(true)
	
	#stats.health_changed.connect(_on_health_changed)
	stats.health_depleted.connect(_on_health_depleted)

#region pathfinding

func _physics_process(_delta: float) -> void:
	var current_pos: Vector2 = self.global_transform.origin
	var next_path_pos: Vector2 = nav_agent.get_next_path_position()
	var new_velocity = current_pos.direction_to(next_path_pos)
	nav_agent.velocity = new_velocity
	
	update_target_pos(Global.player.global_transform.origin)

func update_target_pos(target_pos: Vector2):
	nav_agent.target_position = target_pos

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = velocity.move_toward(safe_velocity * move_speed, 12.0)
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
