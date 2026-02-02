extends Area2D

@export var stats: Stats

@export var speed: float = 600.0
var direction: Vector2

@export var move: bool = true


func _ready() -> void:
	#add_to_group("projectiles")
	
	if !move:
		return
	rotation = direction.angle()
	connect("body_entered", _on_body_entered)

func _physics_process(delta: float) -> void:
	if !move:
		return
	
	global_position += direction * speed * delta

func _on_body_entered(_body: Node) -> void:
	$Sprite2D.play("explode")
	speed = 0
	
	rotation = Vector2.ZERO.angle()
	
	add_to_group("deactive")
	await get_tree().create_timer(0.4).timeout
	
	queue_free()
