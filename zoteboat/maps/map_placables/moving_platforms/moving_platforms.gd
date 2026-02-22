extends Path2D


@onready var path_follow_2d: PathFollow2D = $PathFollow2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var loop: bool = false
@export var speed: int = 100
@export var speed_scale: float = 1.0
@export var per_side_wait_time: float = 0.3


@export_group("on trigger")
@export var move_on_trigger: bool = false
@export var trigger_one_direction: bool = false

var triggered: bool = false
var triggered_front: bool = false

var in_trigger: bool = false

func _ready() -> void:
	add_to_group("moving_platform")
	
	if !loop:
		animation_player.speed_scale = speed_scale
		set_process(false)
		
		if !move_on_trigger:
			animation_player.play("front")



func _process(delta: float) -> void:
	path_follow_2d.progress += speed * delta


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	await get_tree().create_timer(per_side_wait_time).timeout
	if move_on_trigger:
		if $AnimationPlayer.assigned_animation == "RESET":
			return
		
		if anim_name == "front":
			if !trigger_one_direction:
				animation_player.play("back")
			else:
				triggered_front = true
				triggered = false
				if in_trigger:
					animation_player.play("back")
		elif anim_name == "back":
			triggered = false
			if trigger_one_direction:
				triggered_front = false
			if in_trigger:
				animation_player.play("front")
	
	else:
		if anim_name == "front":
			animation_player.play("back")
		elif anim_name == "back":
			animation_player.play("front")
	


func _on_move_trigger_body_entered(body: Node2D) -> void:
	if !move_on_trigger || !body.is_in_group("player"):
		return
	in_trigger = true
	
	if triggered:
		return
	
	triggered = true
	
	if !trigger_one_direction:
		animation_player.play("front")
		return
	
	if triggered_front:
		animation_player.play("back")
	else:
		animation_player.play("front")
	


func _on_move_trigger_body_exited(body: Node2D) -> void:
	if !move_on_trigger || !body.is_in_group("player"):
		return
	
	in_trigger = false
