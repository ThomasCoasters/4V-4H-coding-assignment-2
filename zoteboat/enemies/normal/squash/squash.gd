extends CharacterBody2D
#region setup

@export var stats: Stats

@export var player_decector: RayCast2D

signal killed(node: Node2D)

@export var start_active := true

@export var move_speed: int = 300
@export var jump_speed: int = -700
@export var max_jump_time: float = 0.5

var jump_timer: float = 0.0
var attack_direction: Vector2 = Vector2.ZERO

@export var gravity: int = 1200
@export var fall_speed: int = 4000

@export var fall_mult: float = 1.5

var player_in_attack_range: bool = false

func _ready() -> void:
	if !start_active:
		deactivate()
	
	
	if stats != null:
		stats = stats.duplicate(true)
	
	#stats.health_changed.connect(_on_health_changed)
	stats.health_depleted.connect(_on_health_depleted)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	Global.player.jumping.connect(_on_player_jump)
#endregion

#region basic enemy stuff
func activate():
	set_process(true)
	set_physics_process(true)
	
	self.remove_from_group("deactive")

func deactivate():
	set_process(false)
	set_physics_process(false)
	
	self.add_to_group("deactive")


func damage(damage_value: int):
	stats.health -= damage_value

func i_frames(time):
	add_to_group("invincible")
	await get_tree().create_timer(time).timeout
	remove_from_group("invincible")


func _on_health_depleted():
	killed.emit(self)
#endregion



#region attack
func _on_player_jump():
	$StateChart.send_event("attack")

func _on_attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = true


func _on_attack_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = false




func _on_attack_state_entered() -> void:
	jump_timer = max_jump_time
	
	# Direction toward player (horizontal only)
	attack_direction = (Global.player.global_position - global_position).normalized()
	attack_direction.y = 0
	
	# Initial jump impulse
	velocity.y = jump_speed
	velocity.x = attack_direction.x * move_speed


func _physics_process(delta: float) -> void:
	if player_in_attack_range:
		$StateChart.send_event("attack")
	
	
	if $StateChart/attacks/attack.active:
		handle_attack_movement(delta)
	else:
		apply_gravity(delta)
	
	move_and_slide()


func handle_attack_movement(delta: float) -> void:
	if jump_timer > 0 && !player_decector.is_colliding():
		velocity.y += gravity * delta
		
		if velocity.y > 0:
			velocity = Vector2.ZERO
			
			jump_timer -= delta
	else:
		jump_timer = 0
		
		velocity.y += gravity * delta * fall_mult
		velocity.y = min(velocity.y, fall_speed)
		
		velocity.x = 0
		
		if is_on_floor():
			velocity = Vector2.ZERO
			$StateChart.send_event("stop_attack")


func apply_gravity(delta: float) -> void:
	if !is_on_floor():
		velocity.y += gravity * delta
#endregion
