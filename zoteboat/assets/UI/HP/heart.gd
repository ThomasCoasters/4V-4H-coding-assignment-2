extends Control
@onready var hearth: AnimatedSprite2D = $hearth
var full: bool = true



func set_full(value: bool):
	if value:
		if full:
			return
		full = true
		hearth.play("full")
	else:
		if !full:
			return
		full = false
		hearth.play("empty")




func _on_hearth_animation_finished() -> void:
	if full:
		hearth.play("shine")
