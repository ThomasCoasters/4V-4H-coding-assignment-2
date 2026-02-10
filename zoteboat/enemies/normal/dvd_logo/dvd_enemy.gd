@tool
extends CharacterBody2D

@export var stats: Stats

signal killed(node: Node2D)

@export var speed: int = 200
@export var start_active := true

var direction: Vector2 = Vector2.RIGHT

@export_range(0, 360, 0.1)
var angle: float:
	set(value):
		_angle_deg = value
		var rad := deg_to_rad(_angle_deg)
		direction = Vector2.RIGHT.rotated(rad)
		queue_redraw()
	get:
		return _angle_deg

var _angle_deg := 0.0



var current_anim: String

enum ANIM_PRIORITY {
	FLY,
	DEATH,
	LAND_DEATH
}

var current_anim_priority: int = 0

var dead: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		direction = Vector2.RIGHT.rotated(angle)
		queue_redraw()
		return
	
	if !start_active:
		deactivate()
	
	if stats != null:
		stats = stats.duplicate(true)
	
	#stats.health_changed.connect(_on_health_changed)
	stats.health_depleted.connect(_on_health_depleted)
	
	$Sprite2D.flip_h = direction.x > 0
	$Sprite2D.animation_finished.connect(_on_animation_finished)
	
	add_to_group("dvd_enemy")

func activate():
	set_process(true)
	set_physics_process(true)
	
	self.remove_from_group("deactive")

func deactivate():
	set_process(false)
	set_physics_process(false)
	
	self.add_to_group("deactive")



func damage(damage_value: int):
	stats.health -= damage_value

func i_frames(time):
	add_to_group("invincible")
	await get_tree().create_timer(time).timeout
	remove_from_group("invincible")




func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if dead:
		velocity.y += 3000 * delta
		@warning_ignore("confusable_local_declaration")
		var collision = move_and_collide(velocity*delta)
		
		if collision:
			if collision.get_normal().dot(Vector2.UP) > 0.7:
				print("landed")
				play_anim("death(land)", 999)
				velocity = Vector2.ZERO
		
		return
	
	
	velocity = direction * speed
	
	var collision = move_and_collide(velocity*delta)
	if collision:
		direction = direction.bounce(collision.get_normal())
		angle = rad_to_deg(direction.angle())
		
		$Sprite2D.flip_h = direction.x > 0


func _on_health_depleted():
	play_anim("death(air)")
	dead = true
	
	add_to_group("deactive")
	
	self.add_to_group("invincible")




func play_anim(anim_name: String = "idle", priority: int = 0):
	if priority < current_anim_priority || current_anim_priority == 999:
		return
	
	if anim_name == "death(land)":
		velocity = Vector2.ZERO
	
	current_anim_priority = priority
	
	
	current_anim = anim_name
	
	$Sprite2D.play(anim_name)

func _on_animation_finished():
	current_anim_priority = 0
	
	if current_anim == "death(land)":
		killed.emit(self)



func _draw():
	if not Engine.is_editor_hint():
		return
	
	var arrow_length := 40.0
	var arrow_width := 6.0
	
	var dir := direction.normalized()
	var end := dir * arrow_length
	
	# Main line
	draw_line(Vector2.ZERO, end, Color.RED, 2)
	
	# Arrow head
	var left := end + dir.rotated(PI * 0.75) * arrow_width
	var right := end + dir.rotated(-PI * 0.75) * arrow_width
	
	draw_line(end, left, Color.RED, 2)
	draw_line(end, right, Color.RED, 2)
