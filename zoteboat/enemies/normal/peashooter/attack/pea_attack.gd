extends Area2D

@export var stats: Stats
@export var speed: float = 600.0
var direction: Vector2

@onready var screen_notifier := $VisibleOnScreenNotifier2D

func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	screen_notifier.screen_exited.connect(_on_screen_exited)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_screen_exited() -> void:
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		queue_free()
