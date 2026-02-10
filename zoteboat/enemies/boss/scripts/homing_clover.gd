extends Area2D
@export var stats: Stats
@export var speed: float = 450.0

@export var active_time: float = 5.0

@export_range(0.5, 8.0, 0.1)
var turn_rate: float = 2.5

var direction: Vector2 = Vector2.RIGHT

@onready var screen_notifier := $VisibleOnScreenNotifier2D
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var your_taking_too_long: Timer = $YOUR_TAKING_TOO_LONG
@onready var start_straight: Timer = $start_straight


var homing: bool = true

func _ready() -> void:
	your_taking_too_long.wait_time = active_time
	your_taking_too_long.start()
	start_straight.start()
	
	direction = direction.normalized()
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	screen_notifier.screen_exited.connect(_on_screen_exited)
	add_to_group("projectiles")
	
	

func _physics_process(delta: float) -> void:
	if Global.player && homing && start_straight.is_stopped():
		var to_player = (Global.player.global_position - global_position).normalized()
		
		var angle := direction.angle_to(to_player)
		
		var turn_amount = sign(angle) * turn_rate * delta
		
		if abs(turn_amount) > abs(angle):
			turn_amount = angle
		
		direction = direction.rotated(turn_amount)
		rotation = direction.angle()
	
	global_position += direction * speed * delta

func _on_screen_exited() -> void:
	queue_free()

func _on_body_entered(_body: Node = self) -> void:
	sprite_2d.play("stop")
	homing = false


func _on_your_taking_too_long_timeout() -> void:
	_on_body_entered()
