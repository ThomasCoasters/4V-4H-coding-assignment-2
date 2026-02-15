extends Path2D


@onready var path_follow_2d: PathFollow2D = $PathFollow2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var loop: bool = false
@export var speed: int = 100
@export var speed_scale: float = 1.0

@export_group("on trigger")
@export var move_on_trigger: bool = false
@export var trigger_one_direction: bool = false

var triggered: bool = false
var triggered_front: bool = false

func _ready() -> void:
	if !loop:
		animation_player.speed_scale = speed_scale
		set_process(false)
		
		if !move_on_trigger:
			animation_player.play("front")



func _process(delta: float) -> void:
	path_follow_2d.progress += speed * delta


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if move_on_trigger:
		if anim_name == "front":
			if !trigger_one_direction:
				animation_player.play("back")
			else:
				triggered_front = true
				triggered = false
		elif anim_name == "back":
			triggered = false
			if trigger_one_direction:
				triggered_front = false
	
	else:
		if anim_name == "front":
			animation_player.play("back")
		elif anim_name == "back":
			animation_player.play("front")
	


func _on_move_trigger_body_entered(body: Node2D) -> void:
	if !move_on_trigger || !body.is_in_group("player") || triggered:
		return
	
	triggered = true
	
	if !trigger_one_direction:
		animation_player.play("front")
		return
	
	if triggered_front:
		animation_player.play("back")
	else:
		animation_player.play("front")
	
