extends Node2D

@onready var wp_globe_upright_0000: Sprite2D = $WpGlobeUpright0000
@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var node_2d: Node2D = $Node2D
@onready var collision_polygon_2d: CollisionPolygon2D = $CollisionPolygon2D
@onready var rigid_body_2d: RigidBody2D = $Node2D/RigidBody2D

@export_group("lumafly stuff")
const LUMAFLY = preload("uid://b3vebb80piqur")
@export var release_lumafly: bool = false
@export var lumafly_end_zone: Area2D

func break_object():
	wp_globe_upright_0000.visible = false
	point_light_2d.enabled = false
	collision_polygon_2d.set_deferred("disabled", true)
	
	node_2d.visible = true
	
	for part: RigidBody2D in node_2d.get_children():
		part.set_deferred("freeze", false)
		part.linear_velocity = Vector2(
			randf_range(-300, 300),
			randf_range(-200, -100)
		)
		part.angular_velocity = randf_range(-deg_to_rad(300), deg_to_rad(300))
	
	remove_from_group("breakable_object")
	
	
	
	if release_lumafly:
		var end_location: Vector2 = Vector2.ZERO
		if lumafly_end_zone:
			end_location = lumafly_end_zone.global_position
		
		lumafly_to_location(global_position + Vector2(0, -80), end_location)
	
	await get_tree().create_timer(12.0).timeout
	
	var tween := get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "modulate:a", 0.0, 0.7). from(1.0)
	tween.finished.connect(func():
		queue_free()
	)


func lumafly_to_location(start_pos, end_pos):
	var lumafly: = LUMAFLY.instantiate()
	
	var curve: Curve2D = Curve2D.new()
	
	curve.add_point(start_pos)
	curve.add_point(end_pos)
	
	lumafly.curve = curve
	
	get_tree().current_scene.add_child(lumafly)
