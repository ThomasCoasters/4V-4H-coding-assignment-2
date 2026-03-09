extends Path2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var point_light_2d: PointLight2D = $PathFollow2D/PointLight2D
@onready var sprite_2d: Sprite2D = $PathFollow2D/Sprite2D



@export_group("afterimage")
@export var afterimage_scene: PackedScene
@export var afterimage_spawn_delay := 0.06
@export var afterimage_min_radius := 24.0
@export var afterimage_max_radius := 64.0
@export var afterimage_color := Color(1, 1, 1, 0.7)


var _afterimage_timer := 0.0
var _afterimage_active := true

func _ready() -> void:
	animation_player.current_animation = "fly"

func _physics_process(delta: float) -> void:
	if _afterimage_active:
		_afterimage_timer -= delta
		if _afterimage_timer <= 0.0:
			spawn_afterimage()
			_afterimage_timer = afterimage_spawn_delay

func spawn_afterimage():
	if afterimage_scene == null:
		return
	
	var img := afterimage_scene.instantiate()
	get_parent().add_child(img)
	
	var angle := randf() * TAU
	var radius := randf_range(afterimage_min_radius, afterimage_max_radius)
	var offset := Vector2(cos(angle), sin(angle)) * radius
	
	img.global_position = sprite_2d.global_position + offset
	img.rotation = sprite_2d.rotation
	img.modulate = afterimage_color
	
	var s := img.get_node("Sprite2D") as Sprite2D
	s.global_scale = sprite_2d.global_scale
	s.texture = sprite_2d.texture
	s.flip_h = sprite_2d.flip_h


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	var tween := get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "modulate:a", 0.0, 0.7). from(1.0)
	tween.parallel().tween_property(point_light_2d, "energy", 0.0, 0.7). from(1.0)
	tween.finished.connect(func():
		queue_free()
	)
