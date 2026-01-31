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

@export var dialogue: String = "welcome"
@export var scared: bool = false
@export var explain_talk: bool = false
@export var explain_text: String = ""
var visible_explain_text: bool = false

func _ready() -> void:
	$Sprite2D.animation_finished.connect(_on_animation_finished)
	
	$Sprite2D2.visible = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	entered = true
	$Sprite2D2.visible = true
	
	if !explain_talk || visible_explain_text:
		return
	
	await get_tree().create_timer(4.0).timeout
	
	if !entered:
		return
	
	visible_explain_text = true
	Global.Name_text.reveal_text(explain_text, 0.25)



func _on_area_2d_body_exited(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	entered = false
	$Sprite2D2.visible = false
	
	if visible_explain_text:
		Global.Name_text.remove_text(0.25)


func _physics_process(_delta: float) -> void:
	update_facing()
	
	if facing_dir == -1:
		play_anim("idle(right)", ANIM_PRIORITY.IDLE)
	else:
		play_anim("idle(left)", ANIM_PRIORITY.IDLE)
	
	
	if !entered:
		if !(current_anim == "idle(right)" || current_anim == "idle(left)" || current_anim == "turn"):
			current_anim_priority = 0
		return
	
	if Global.player.direction.y == 1 && !Global.player.moving.active:
		Global.dialogue.start(dialogue)
		
		if facing_dir == -1:
			play_anim("talk(right)", ANIM_PRIORITY.TALK)
		else:
			play_anim("talk(left)", ANIM_PRIORITY.TALK)




#region animations
func play_anim(anim_name: String = "idle", priority: int = 0):
	if priority < current_anim_priority:
		return
	
	current_anim_priority = priority
	
	
	current_anim = anim_name
	
	if scared:
		$Sprite2D.play("scared")
		return
	if anim_name == "turn" && facing_dir == 1:
		$Sprite2D.play_backwards(anim_name)
	else:
		$Sprite2D.play(anim_name)

func _on_animation_finished():
	current_anim_priority = 0



func update_facing():
	if current_anim == "attack" || current_anim == "death":
		return
	
	
	var new_dir = sign(Global.player.global_position.x - global_position.x)
	
	# Player exactly on top -> ignore
	if new_dir == 0:
		return
	
	# Only react when direction changes
	if new_dir != facing_dir:
		facing_dir = new_dir
		play_anim("turn", 5)
#endregion
