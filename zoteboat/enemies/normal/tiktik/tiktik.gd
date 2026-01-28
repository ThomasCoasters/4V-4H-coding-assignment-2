extends CharacterBody2D

@export var stats: Stats

signal killed(node: Node2D)

@export var start_active := true

@export var speed: float = 100
@onready var path_follow_2d: PathFollow2D = $".."
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D

var walking: bool = true


var current_anim: String

enum ANIM_PRIORITY {
	WALK,
	STUN,
	DEATH,
	LAND_DEATH
}

var current_anim_priority: int = 0

var dead: bool = false

func _ready() -> void:
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
	play_anim("stun")
	walking = false
	
	stats.health -= damage_value

func i_frames(time):
	add_to_group("invincible")
	await get_tree().create_timer(time).timeout
	remove_from_group("invincible")

func _on_health_depleted():
	play_anim("death(air)")
	var dir = sign(global_position - Global.player.global_position)
	
	velocity = Vector2(300*dir.x, -800)
	dead = true
	
	add_to_group("deactive")
	
	self.add_to_group("invincible")

func _process(delta: float) -> void:
	if dead:
		velocity.y += 3000 * delta
		move_and_slide()
		if is_on_floor():
			play_anim("death(land)")
		
		return
	
	if !walking:
		return
	path_follow_2d.progress += speed * delta




func play_anim(anim_name: String = "idle", priority: int = 0):
	if priority < current_anim_priority:
		return
	
	if anim_name == "death(land)":
		velocity = Vector2.ZERO
	
	current_anim_priority = priority
	
	
	current_anim = anim_name
	
	$Sprite2D.play(anim_name)

func _on_animation_finished():
	current_anim_priority = 0
	
	if current_anim == "stun":
		await  get_tree().create_timer(0.2).timeout
		play_anim("walk")
		walking = true
	
	if current_anim == "death(land)":
		killed.emit(self)
