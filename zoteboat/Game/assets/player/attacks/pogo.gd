extends Area2D

var speed : float
@export var acceleration : int
var returning := false
var return_target: Vector2

func _physics_process(delta: float) -> void:
	if returning:
		# Smooth movement back to the player
		global_position = global_position.lerp(return_target, 5 * delta)

		# Stop when close enough
		if global_position.distance_to(return_target) < 5:
			returning = false
		return

	# Normal falling behavior
	speed += acceleration
	position.y += speed


func _on_body_entered(body: Node2D) -> void:
	print("Hit:", body)

	# Ignore player
	if body.is_in_group("player"):
		return

	# Start return process
	var player = get_tree().get_first_node_in_group("player")
	if player:
		return_target = player.global_position
		returning = true
		speed = 0
