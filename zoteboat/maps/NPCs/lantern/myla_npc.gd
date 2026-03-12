extends Node2D

var entered: bool = false

var current_anim: String

enum ANIM_PRIORITY {
	IDLE,
	TURN,
	TALK
}

var current_anim_priority: int = 0

var facing_dir: int = -1 # -1 = left           1 = right

@export var dialogue: String = "lantern_tip"
@export var enable_repeat_dialogue: bool = false
@export var repeat_dialogue: String = "lantern_tip_repeat"

func _ready() -> void:
	$Sprite2D.animation_finished.connect(_on_animation_finished)
	
	$Sprite2D2.visible = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	entered = true
	$Sprite2D2.visible = true
	
	await get_tree().create_timer(4.0).timeout



func _on_area_2d_body_exited(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	entered = false
	$Sprite2D2.visible = false
	
	current_anim_priority = 0
	play_anim("talk(end)", ANIM_PRIORITY.TALK)


func _physics_process(_delta: float) -> void:
	play_anim("idle", ANIM_PRIORITY.IDLE)
	
	if Global.player.direction.y == 1 && !Global.player.moving.active:
		Global.dialogue.start(dialogue)
		
		play_anim("talk(start)", ANIM_PRIORITY.TALK)
		
		if enable_repeat_dialogue:
			dialogue = repeat_dialogue




#region animations
func play_anim(anim_name: String = "idle", priority: int = 0):
	if priority < current_anim_priority:
		return
	
	current_anim_priority = priority
	
	
	current_anim = anim_name
	
	$Sprite2D.play(anim_name)

func _on_animation_finished():
	current_anim_priority = 0
	
	if current_anim == "talk(start)":
		play_anim("talk", ANIM_PRIORITY.TALK)
#endregion
