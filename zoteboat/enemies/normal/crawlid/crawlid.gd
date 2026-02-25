extends CharacterBody2D

@export var stats: Stats

signal killed(node: Node2D)

@export var start_active := true

@export var speed: float = 100
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D

var turn_cooldown := 0.0

var walking: bool = true

var dir: int = 1

var current_anim: String

enum ANIM_PRIORITY {
	WALK,
	TURN,
	DEATH,
}

var current_anim_priority: int = 0

func _ready() -> void:
	update_direction()
	
	if !start_active:
		deactivate()
	
	
	if stats != null:
		stats = stats.duplicate(true)
	
	#stats.health_changed.connect(_on_health_changed)
	stats.health_depleted.connect(_on_health_depleted)
	
	sprite_2d.animation_finished.connect(_on_animation_finished)

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
	play_anim("death", ANIM_PRIORITY.DEATH)
	walking = false
	
	add_to_group("deactive")
	
	self.add_to_group("invincible")

func _physics_process(delta: float) -> void:
	if !walking:
		return
	
	if !is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.x = speed * dir
	
	if turn_cooldown > 0:
		turn_cooldown -= delta
		move_and_slide()
		return
	
	if is_on_wall() || (!ray_cast_2d.is_colliding() && is_on_floor()):
		walking = false
		play_anim("turn", ANIM_PRIORITY.TURN)
		velocity = Vector2.ZERO
		return
	
	print(dir)
	print(scale.x)
	
	move_and_slide()
	




func play_anim(anim_name: String = "idle", priority: int = 0):
	if priority < current_anim_priority:
		return
	
	if anim_name == "death":
		velocity = Vector2.ZERO
	
	current_anim_priority = priority
	
	
	current_anim = anim_name
	
	sprite_2d.play(anim_name)

func _on_animation_finished():
	current_anim_priority = 0
	
	if current_anim == "turn":
		dir = -dir
		global_position.x += speed * 0.05 * dir
		
		update_direction()
		
		turn_cooldown = 0.2
		
		play_anim("walk")
		walking = true
		
	
	if current_anim == "death":
		killed.emit(self)


func update_direction():
	sprite_2d.flip_h = dir == 1
	
	ray_cast_2d.position.x = abs(ray_cast_2d.position.x) * dir
