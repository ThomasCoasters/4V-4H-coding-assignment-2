extends Area2D

@export var stats: Stats

@export var bottom_out_view_px: int = 100

@export var speed: float = 300.0
@export var vertical_speed: float = 200.0

var start_y: float
var target_y: float
var traveled_x: float

@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	await get_tree().process_frame
	start_y = global_position.y - bottom_out_view_px
	target_y = start_y
	
	add_to_group("projectiles")

func _physics_process(delta: float) -> void:
	global_position.x -= speed * delta
	traveled_x += speed * delta
	
	if traveled_x >= 1200:
		global_position.y = min(global_position.y + vertical_speed * delta, target_y + bottom_out_view_px)
		if !visible_on_screen_notifier_2d.is_on_screen():
			queue_free()
	
	elif global_position.y > target_y:
		global_position.y = max(global_position.y - vertical_speed * delta, target_y)
	
