extends Area2D

@export var stats: Stats

@export var speed: float = 600.0
var direction: Vector2



func _ready() -> void:
	rotation = direction.angle()
	connect("body_entered", _on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(_body: Node) -> void:
	queue_free()
