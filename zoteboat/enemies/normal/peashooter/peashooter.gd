extends CharacterBody2D

@export var stats: Stats

signal killed(node: Node2D)

@export var start_active := true

@export var face_left: bool = false 

const PEA_ATTACK = preload("uid://qnsax8xwwgus")

func _ready() -> void:
	if !start_active:
		deactivate()
	
	else:
		activate()
	
	if stats != null:
		stats = stats.duplicate(true)
	
	#stats.health_changed.connect(_on_health_changed)
	stats.health_depleted.connect(_on_health_depleted)

func activate():
	set_process(true)
	set_physics_process(true)
	
	self.remove_from_group("deactive")
	
	scale.x = abs(scale.x)
	if face_left:
		scale.x *= -1

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


#
#func _on_health_changed(current_health: int, max_health: int):
	#print(str(current_health) + " out of " + str(max_health))

func _on_health_depleted():
	killed.emit(self)



#region attack


func _physics_process(delta: float) -> void:
	if !is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()
	
	if $RayCast2D.is_colliding() && $VisibleOnScreenNotifier2D.is_on_screen():
		$StateChart.send_event("attack")
	
	
	if $StateChart/attacks/idle.active:
		$Sprite2D.play("idle")
		$Sprite2D.scale = Vector2(0.1, 0.1)
	




func _on_attack_state_entered() -> void:
	var count := 1
	var angle_per_shot := deg_to_rad(20) # angle between each projectile
	
	var base_dir = (Global.player.global_position - global_position).normalized()
	var base_angle = base_dir.angle()
	
	
	$Sprite2D.play("attack")
	$Sprite2D.scale = Vector2(0.0875, 0.0875)
	
	
	await get_tree().create_timer(0.6).timeout
	
	for i in range(count):
		var projectile = PEA_ATTACK.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position
		
		var offset_index := i - (count - 1) / 2.0
		var angle = base_angle + offset_index * angle_per_shot
		
		var dir := Vector2.RIGHT.rotated(angle)
		projectile.direction = dir
		projectile.rotation = angle
		
		
#endregion


func _on_sprite_2d_animation_finished() -> void:
	$StateChart.send_event("stop_attack")
