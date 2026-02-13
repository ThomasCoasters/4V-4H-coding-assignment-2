extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export var stats: Stats

@export var speed: float = 450.0

@export var active_time: float = 5.0

#region spinir
@export_group("spinning")
@export var spin_up_time: float = 1.2  # seconds before launch

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

@export_group("homing")
@export_range(0.0, 45.0, 0.1)
var homing_strength_deg := 10.0:
	set(value):
		homing_strength_deg = value
		homing_strength_rad = deg_to_rad(value)

var homing_strength_rad := deg_to_rad(8.0)
@export var homing_enabled := true

func _ready() -> void:
	$remove_time.wait_time = active_time
	
	add_to_group("projectiles")
	velocity = Vector2.ZERO
	
	collision_shape_2d.disabled = true
	
	var tween := get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(sprite, "modulate:a", 1.0, spin_up_time). from(0.0)
	tween.parallel().tween_property(sprite, "scale", Vector2(4.5, 4.5), spin_up_time).from(Vector2.ZERO)
	tween.finished.connect(func():
		collision_shape_2d.disabled = false
		_resolve_initial_overlap()
)

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
	
	sprite.rotation -= spin_speed * delta
	
	if spin_timer >= spin_up_time:
		spinning = false
		$remove_time.start()
#endregion

func _move_and_bounce(delta: float) -> void:
	velocity = direction * speed
	
	var collision := move_and_collide(velocity * delta)
	if collision:
		direction = direction.bounce(collision.get_normal()).normalized()
		direction = _apply_soft_homing(direction)
		
		var hit_effect: GPUParticles2D = $HitEffect
		if hit_effect.emitting:
			hit_effect = $HitEffect2
		
		hit_effect.emitting = true
		hit_effect.rotation = direction.angle() - deg_to_rad(90)
		Global.player.hitstop_manager(0.05, 1.0, "medium")
	
	sprite.rotation -= spin_speed * delta

func _apply_soft_homing(current: Vector2) -> Vector2:
	if Global.player == null:
		return current
	
	var to_player = Global.player.global_position - global_position
	if to_player == Vector2.ZERO:
		return current
	
	var target_dir = to_player.normalized()
	
	var angle_diff := current.angle_to(target_dir)
	angle_diff = clamp(angle_diff, -homing_strength_rad, homing_strength_rad)
	
	return current.rotated(angle_diff).normalized()




func _on_remove_time_timeout() -> void:
	direction = Vector2.ZERO
	collision_shape_2d.disabled = true
	
	var tween := get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(sprite, "modulate:a", 0.0, 1.5). from(1.0)
	tween.parallel().tween_property(sprite, "scale", Vector2.ZERO, 1.5).from(Vector2(4.5, 4.5))
	tween.finished.connect(func():
		queue_free()
)






func _resolve_initial_overlap():
	var space_state = get_world_2d().direct_space_state
	
	var max_push_distance := 256.0
	var step := 4.0
	var pushed := 0.0
	
	while pushed < max_push_distance:
		var params := PhysicsShapeQueryParameters2D.new()
		params.shape = collision_shape_2d.shape
		params.transform = global_transform
		params.collision_mask = collision_mask
		params.exclude = [self]
		
		var result = space_state.intersect_shape(params, 1)
		
		if result.is_empty():
			return # ✅ we're clear
		
		# push forward along shooting direction
		global_position += direction.normalized() * step
		pushed += step
	
	# failsafe: if somehow still overlapping
	print("Scythe overlap resolve exceeded max distance")
