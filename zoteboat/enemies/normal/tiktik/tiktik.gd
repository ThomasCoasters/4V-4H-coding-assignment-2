extends CharacterBody2D

@export var stats: Stats

signal killed(node: Node2D)

@export var start_active := true

@export var speed: float = 100
@onready var path_follow_2d: PathFollow2D = $".."

func _ready() -> void:
	if !start_active:
		deactivate()
	
	
	if stats != null:
		stats = stats.duplicate(true)
	
	#stats.health_changed.connect(_on_health_changed)
	stats.health_depleted.connect(_on_health_depleted)

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




func _process(delta: float) -> void:
	path_follow_2d.progress += speed * delta
