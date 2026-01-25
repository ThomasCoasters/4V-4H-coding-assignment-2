extends Area2D

@export var doors: TileMapLayer

var arena_started: bool = false
var arena_finished: bool = false

@export var camera_pos: Node2D

var current_wave: int = 0

var wave_to_node : Dictionary = {}
@export var wave_holder : Node2D

var player

var alive_enemies := 0


#region enemy scenes
const TEST_DUMMY = preload("res://enemies/examples/test_dummy/test_dummy.tscn")
const DVD_ENEMY = preload("res://enemies/normal/dvd_logo/dvd_enemy.tscn")
const ASPID_ENEMY = preload("uid://3dmnl1rv4c6f")
const SQUASH_ENEMY = preload("uid://cd21npjsi1iei")
const PEASHOOTER_ENEMY = preload("uid://desufiot6ea2v")


const ENEMY_SCENES := {
	"dummy": TEST_DUMMY,
	"dvd": DVD_ENEMY,
	"aspid": ASPID_ENEMY,
	"squash": SQUASH_ENEMY,
	"peashooter": PEASHOOTER_ENEMY,
}
#endregion


signal arena_won(node: Node)

var arena_parent: Node = null

@export var audio_node: AudioStreamPlayer

func _ready():
	arena_parent = self.get_parent()
	await get_tree().process_frame
	await get_tree().process_frame
	
	if doors:
		doors.enabled = false
	
	for wave_number in range(wave_holder.get_child_count()):
		wave_to_node[wave_number+1] = wave_holder.get_child(wave_number)
	
	
	player = Global.player


func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player") || arena_started || arena_finished:
		return
	
	start_arena()


func start_arena():
	arena_started = true
	
	if camera_pos:
		player.forced_position = camera_pos.position
	
	if doors:
		doors.enabled = true
	
	if audio_node:
		audio_node.play()
	
	spawn_wave()

func finish_arena():
	arena_started = false
	arena_finished = true
	if doors:
		doors.enabled = false
	player.current_camera_type = "free"
	
	if is_instance_valid(arena_parent):
		arena_parent.queue_free()
	
	if audio_node:
		audio_node.stop()
	
	arena_won.emit(arena_parent)


func spawn_wave():
	current_wave += 1
	if !wave_to_node.has(current_wave):
		finish_arena()
		return
	
	for spawner in wave_to_node[current_wave].get_children():
		
		if "camera_mode" in spawner.name:
			for mode in spawner.get_children():
				player.current_camera_type = mode.name
		
		var extra := {}
		
		var extra_node = spawner.get_node_or_null("extra")
		if extra_node and extra_node.has_method("get_extras"):
			for kv in extra_node.get_extras():
				extra[kv.key] = kv.value
		
		for key in ENEMY_SCENES:
			if key in spawner.name:
				spawn_enemy(
					ENEMY_SCENES[key],
					spawner.global_position,
					extra
				)







#region enemy spawning
func spawn_enemy(enemy_scene: PackedScene, pos: Vector2, extra := {}) -> void:
	await get_tree().create_timer(0.5).timeout
	
	var enemy := enemy_scene.instantiate()
	
	
	for key in extra:
		enemy.set(key, extra[key])
	
	
	enemy.start_active = false
	get_tree().current_scene.call_deferred("add_child", enemy)
	enemy.global_position = pos
	
	alive_enemies += 1
	enemy.killed.connect(_on_enemy_killed)
	
	fade_in_enemy(enemy, 0.7)

func _on_enemy_killed(enemy):
	alive_enemies -= 1
	enemy.call_deferred("queue_free")
	
	if alive_enemies <= 0:
		spawn_wave()



func fade_in_enemy(enemy: Node2D, duration: float) -> void:
	var tween := get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(enemy, "modulate:a", 1.0, duration). from(0.0)
	tween.parallel().tween_property(enemy, "scale", Vector2.ONE, duration).from(Vector2.ZERO)
	tween.finished.connect(func():
		if enemy.has_method("activate"):
			enemy.activate()
	)
#endregion
