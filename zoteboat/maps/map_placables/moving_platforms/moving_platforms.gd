extends Path2D


@onready var path_follow_2d: PathFollow2D = $PathFollow2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var loop: bool = false
@export var speed: int = 100
@export var speed_scale: float = 1.0

func _ready() -> void:
	if !self.loop:
		animation_player.play("default")
		animation_player.speed_scale = speed_scale
		set_process(false)

func _process(delta: float) -> void:
	path_follow_2d.progress += speed * delta
