extends CharacterBody2D

@export var stats: Stats

@export var speed: float = 300.0

@export var spin_up_time: float = 1.2  # seconds before launch

#region spinir
@export_range(0.0, 3600.0, 1.0)
var max_spin_speed_deg: float = 720.0:
	set(value):
		max_spin_speed_deg = value
		max_spin_speed_rad = deg_to_rad(value)

var max_spin_speed_rad: float = deg_to_rad(720.0)

var direction: Vector2 = Vector2.RIGHT

var spinning := true
var spin_speed := 0.0
var spin_timer := 0.0
#endregion

func _ready() -> void:
	add_to_group("projectiles")
	velocity = Vector2.ZERO

#region spinnin'
func _physics_process(delta: float) -> void:
	if spinning:
		_spin_up(delta)
	else:
		_move_and_bounce(delta)

func _spin_up(delta: float) -> void:
	spin_timer += delta
	
	var t = clamp(spin_timer / spin_up_time, 0.0, 1.0)
	
	spin_speed = lerp(0.0, max_spin_speed_rad, ease(t, -2.0))
	
	$Sprite2D.rotation -= spin_speed * delta
	
	if spin_timer >= spin_up_time:
		spinning = false
		$remove_time.start()
#endregion

func _move_and_bounce(delta: float) -> void:
	velocity = direction * speed
	
	var collision := move_and_collide(velocity * delta)
	if collision:
		direction = direction.bounce(collision.get_normal()).normalized()
	
	$Sprite2D.rotation -= spin_speed * delta


func _on_remove_time_timeout() -> void:
	$CollisionShape2D.disabled = true
	
	var tween := get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.5). from(1.0)
	tween.parallel().tween_property($Sprite2D, "scale", Vector2.ZERO, 0.5).from(Vector2.ONE)
	tween.finished.connect(func():
		queue_free()
)
