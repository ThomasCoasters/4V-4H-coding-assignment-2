extends Area2D

var speed : float
@export var acceleration : int
var returning := false
var return_target: Vector2

signal pogo_returned

func _physics_process(delta: float) -> void:
	if returning:
		speed += 0.2
		var player = get_tree().get_first_node_in_group("player")
		return_target = player.global_position
		# Smooth movement back to the player
		global_position = global_position.lerp(return_target, speed * delta)
		
		return

	# Normal falling behavior
	speed += acceleration
	position.y += speed


func _on_body_entered(body: Node2D) -> void:
	print("Hit:", body)

	# Ignore player
	if body.is_in_group("player"):
		if returning:
			pogo_returned.emit()
		return

	# Start return process
	var player = get_tree().get_first_node_in_group("player")
	if player && !returning:
		returning = true
		speed = 0
