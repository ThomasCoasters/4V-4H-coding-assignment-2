extends Area2D

var speed : float
@export var acceleration : int
var returning := false
var return_target: Vector2

signal pogo_returned

func _physics_process(delta: float) -> void:
	if returning:
		speed += 12
		var player = get_tree().get_first_node_in_group("player")
		return_target = player.global_position
		# Smooth movement back to the player
		global_position = global_position.move_toward(return_target, speed * delta)
		
		look_at(return_target)
		
		if global_position.distance_to(return_target) < 35:
			pogo_returned.emit()
		
		return

	# Normal falling behavior
	speed += acceleration
	position.y += speed
	rotate(0.3)

func _on_area_entered(area: Area2D) -> void:
	something_entered(area)

func _on_body_entered(body: Node2D) -> void:
	something_entered(body)

func something_entered(thing):
	# Ignore player
	if thing.is_in_group("player"):
		return
	
	
	
	# Start return process
	var player = get_tree().get_first_node_in_group("player")
	if player && !returning:
		returning = true
		speed = 300
