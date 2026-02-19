extends Node2D

var entered: bool = false

@export var dialogue: String = "welcome"
@export var explain_talk: bool = false
@export var explain_text: String = ""
var visible_explain_text: bool = false

func _ready() -> void:
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
	if !entered:
		return
	
	if Global.player.direction.y == 1 && !Global.player.moving.active:
		Global.dialogue.start(dialogue)
