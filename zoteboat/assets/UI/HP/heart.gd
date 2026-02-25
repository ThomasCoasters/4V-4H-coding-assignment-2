extends Control
@onready var hearth: AnimatedSprite2D = $hearth
var full: bool


func set_full(value: bool):
	if value:
		full = true
		hearth.play("full")
	else:
		hearth.play("empty")




func _on_hearth_animation_finished() -> void:
	if full:
		full = false
		hearth.play("shine")
