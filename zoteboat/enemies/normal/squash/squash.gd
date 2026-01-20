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

@export var fall_mult: float = 4

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
	jump_timer = max_jump_time * randf_range(0.8, 1.2)
	
	# Direction toward player (horizontal only)
	attack_direction = (Global.player.global_position - global_position).normalized()
	attack_direction.y = 0
	
	velocity.y = jump_speed * randf_range(0.8, 1.2)


func _physics_process(delta: float) -> void:
	$body.flip_h = Global.player.global_position.x < global_position.x
	
	#update_eyes()
	
	if player_in_attack_range:
		$StateChart.send_event("attack")
	
	
	if $StateChart/attacks/attack.active:
		handle_attack_movement(delta)
	
	
	if is_on_floor() || !$StateChart/attacks/attack.active:
		apply_gravity(delta)
		
		$body.scale.y = lerp($body.scale.y, 0.35, 0.5)
		$body.position.y = lerp($body.position.y, -17.0, 0.5)
	
	move_and_slide()



func handle_attack_movement(delta: float) -> void:
	if jump_timer > 0:
		velocity.y += gravity * delta
		
		if velocity.y > 0 || player_decector.is_colliding():
			velocity = Vector2.ZERO
			
			jump_timer -= delta
			
			$body.scale.y = lerp($body.scale.y, 0.1, 0.2)
			$body.position.y = lerp($body.position.y, 17.0, 0.2)
		
		else:
			velocity.x = attack_direction.x * move_speed
			
			$body.scale.y = lerp($body.scale.y, 0.5, 0.2)
			$body.position.y = lerp($body.position.y, -27.0, 0.2)
	else:
		jump_timer = 0
		
		velocity.y += gravity * delta * fall_mult
		velocity.y = min(velocity.y, fall_speed)
		
		velocity.x = 0
		
		$body.scale.y = lerp($body.scale.y, 0.2, 0.1)
		$body.position.y = lerp($body.position.y, 0.0, 0.1)
		
		if is_on_floor():
			$body.scale.y = lerp($body.scale.y, 0.35, 0.1)
			$body.position.y = lerp($body.position.y, -17.0, 0.1)
			
			velocity = Vector2.ZERO
			$StateChart.send_event("stop_attack")


func apply_gravity(delta: float) -> void:
	if !is_on_floor():
		velocity.y += gravity * delta
#endregion



##region eye tracking
#func update_eyes():
	#if Global.player == null:
		#return
	#
	#var to_player = (Global.player.global_position - global_position).normalized()
	#
	#var x_offset = lerp(-1.0, 3.0, to_player.x)
	#
	## Vertical look
	#var y_offset = lerp(-15.0, -17.0, clamp(-to_player.y, 0.0, 1.0))
	#y_offset = lerp(y_offset, -13.0, clamp(to_player.y, 0.0, 1.0))
	#
	#eyes.position = eyes.position.lerp(Vector2(x_offset, y_offset), 0.15)
##endregion
