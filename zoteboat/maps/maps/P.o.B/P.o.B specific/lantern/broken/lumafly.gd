extends Path2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var point_light_2d: PointLight2D = $PathFollow2D/PointLight2D

func _ready() -> void:
	animation_player.current_animation = "fly"


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	var tween := get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "modulate:a", 0.0, 0.7). from(1.0)
	tween.parallel().tween_property(point_light_2d, "energy", 0.0, 0.7). from(1.0)
	tween.finished.connect(func():
		queue_free()
	)
