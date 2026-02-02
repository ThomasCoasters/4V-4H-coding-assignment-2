extends Node2D

var entered: bool = false

@export var own_spawning_group: String = "bench"
@onready var bench_rest: AudioStreamPlayer = $BenchRest

func _ready() -> void:
	entered = false
	$Sprite2D2.visible = false
	$Sprite2D.play("default")
	
	add_to_group(own_spawning_group)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	entered = true
	$Sprite2D2.visible = true
	$Sprite2D.play("lit")



func _on_area_2d_body_exited(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	entered = false
	$Sprite2D2.visible = false
	$Sprite2D.play("default")


func _physics_process(_delta: float) -> void:
	if Global.player.direction.y == 1 && !Global.player.moving.active && entered:
		if !$Bench_save.emitting && !bench_rest.playing:
			$Bench_save.emitting = true
			play_audio(bench_rest)
		
		Global.player.health = Global.player.max_health
		
		SaveLoad.contents_to_save.starting_room = Global.map.scene_file_path
		SaveLoad.contents_to_save.starting_location = own_spawning_group
		
		SaveLoad._save()


func play_audio(audio: AudioStreamPlayer):
	audio.pitch_scale = randf_range(0.9, 1.1)
	audio.play()
