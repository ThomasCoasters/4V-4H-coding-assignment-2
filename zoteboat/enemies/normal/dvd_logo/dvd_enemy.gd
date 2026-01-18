extends CharacterBody2D

@export var stats: Stats

signal killed(node: Node2D)

@export var speed: int = 200

var direction: Vector2

@export var start_active := true

func _ready() -> void:
	if !start_active:
		deactivate()
	
	if stats != null:
		stats = stats.duplicate(true)
	
	#stats.health_changed.connect(_on_health_changed)
	stats.health_depleted.connect(_on_health_depleted)
	
	
	direction = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()
	
	add_to_group("dvd_enemy")

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




func _physics_process(delta: float) -> void:
	velocity = direction * speed
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		direction = direction.bounce(collision.get_normal())

func _on_health_depleted():
	killed.emit(self)
