extends Node2D

@onready var wp_globe_upright_0000: Sprite2D = $WpGlobeUpright0000
@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var node_2d: Node2D = $Node2D
@onready var collision_polygon_2d: CollisionPolygon2D = $CollisionPolygon2D
@onready var rigid_body_2d: RigidBody2D = $Node2D/RigidBody2D

@export_group("lumafly stuff")
const LUMAFLY = preload("uid://b3vebb80piqur")
@export var release_lumafly: bool = false

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
		lumafly_to_location(rigid_body_2d.global_position)


func lumafly_to_location(start_pos):
	var lumafly: = LUMAFLY.instantiate()
	
	var curve: Curve2D = lumafly.curve
	
	curve.add_point(start_pos)
	curve.add_point(start_pos-Vector2(200, 10))
	
	add_child(lumafly)
	
	lumafly.global_position = Vector2.ZERO
