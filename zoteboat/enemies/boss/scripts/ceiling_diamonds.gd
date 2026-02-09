extends Area2D

@export var stats: Stats

@export var speed: float = 300.0
var traveled_y: float

@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var marker: Sprite2D = $marker

@export var top_out_view_px: int = 100

@export var start_move_timer: float = 0.5
var moving: bool = false

func _ready() -> void:
	add_to_group("projectiles")
	
	var tween := get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(marker, "modulate:a", 0.0, 0.5).from(1.0)
	tween.finished.connect(func():
		moving = true
	)

func _physics_process(delta: float) -> void:
	if !moving:
		return
	
	global_position.y += speed * delta
	traveled_y += speed * delta
	
	if traveled_y >= 500:
		if !visible_on_screen_notifier_2d.is_on_screen():
			queue_free()
