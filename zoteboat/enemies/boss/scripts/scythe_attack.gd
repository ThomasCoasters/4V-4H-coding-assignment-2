extends Area2D

@export var stats: Stats

@export var speed: float = 600.0
var direction: Vector2



func _ready() -> void:
	rotation = direction.angle()
	
	add_to_group("projectiles")

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
