@tool
extends CharacterBody2D

@export var stats: Stats

signal killed(node: Node2D)

@export var speed: int = 200

var direction: Vector2

@export var start_active := true


@export_range(0, 360, 0.1, "radians_as_degrees")
var angle: float : 
	set(value):
		angle = value
		direction = Vector2.RIGHT.rotated(angle)
		queue_redraw()



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
	
	velocity = direction * speed
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		direction = direction.bounce(collision.get_normal())
		angle = direction.angle() # keep editor arrow in sync
		queue_redraw()

func _on_health_depleted():
	killed.emit(self)







func _draw():
	if not Engine.is_editor_hint():
		return
	
	var arrow_length := 32.0
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
