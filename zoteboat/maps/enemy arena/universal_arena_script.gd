extends Area2D

@export_group("nodes")
@export var camera_pos: Node2D

var current_wave: int = 0

var wave_to_node : Dictionary = {}
@export var wave_holder : Node2D

@export var arena_bounds: CollisionShape2D


@export_subgroup("map stuff")
@export var doors: TileMapLayer

@export var before_safety_map: TileMapLayer
@export var after_safety_map: TileMapLayer

var arena_started: bool = false
var arena_finished: bool = false


var player

var alive_enemies := 0

var spawning_wave: bool = false

#region enemy scenes
const TEST_DUMMY = preload("res://enemies/examples/test_dummy/test_dummy.tscn")
const DVD_ENEMY = preload("res://enemies/normal/dvd_logo/dvd_enemy.tscn")
const ASPID_ENEMY = preload("uid://3dmnl1rv4c6f")
const SQUASH_ENEMY = preload("uid://cd21npjsi1iei")
const PEASHOOTER_ENEMY = preload("uid://desufiot6ea2v")
const GRIMMKIN_BULLETS = preload("uid://dilsa6aexb0cd")
const PRIMAL_ASPID = preload("uid://dd7mbkekqfnpo")
const GRIMMKIN_CIRCLE = preload("uid://xjvy8yhq3hu6")
const JEVIL_BOSS = preload("uid://fvk1kb0dk2bu")


const ENEMY_SCENES := {
	"dummy": TEST_DUMMY,
	"dvd": DVD_ENEMY,
	"aspid": ASPID_ENEMY,
	"primal": PRIMAL_ASPID,
	"squash": SQUASH_ENEMY,
	"peashooter": PEASHOOTER_ENEMY,
	"grimm_attack": GRIMMKIN_BULLETS,
	"grimm_circle": GRIMMKIN_CIRCLE,
	"jevil": JEVIL_BOSS,
}
#endregion


signal arena_won(node: Node)

var arena_parent: Node = null

@export_group("audio paths")
@export var arena_audio_path: String
@export var win_sfx_audio_path: String
@export var after_audio_path: String

@export_group("slowdown")
@export var enable_slowdown: bool = true
@export_range(0.0, 5.0, 0.01) var slowdown_time: float = 0.6
@export_range(0.0, 1.0, 0.01) var slowdown_speed: float = 0.25

func _ready():
	arena_parent = self.get_parent()
	await get_tree().process_frame
	await get_tree().process_frame
	
	if doors:
		doors.enabled = false
	
	if before_safety_map:
		before_safety_map.enabled = true
	if after_safety_map && before_safety_map != after_safety_map:
		after_safety_map.enabled = false
	
	for wave_number in range(wave_holder.get_child_count()):
		wave_to_node[wave_number+1] = wave_holder.get_child(wave_number)
	
	if arena_bounds:
		Global.map.arena_bounds = arena_bounds
	
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
	
	if arena_audio_path:
		if Global.map_holder.audio_path != arena_audio_path:
			Global.map_holder.new_audio(arena_audio_path)
	
	spawn_wave()
	
	if before_safety_map:
		before_safety_map.enabled = false

func finish_arena():
	Engine.time_scale = slowdown_speed
	
	if win_sfx_audio_path:
		play_sfx(win_sfx_audio_path)
	
	await get_tree().create_timer(slowdown_time, true, false, true).timeout
	
	Engine.time_scale = 1
	
	
	arena_started = false
	arena_finished = true
	if doors:
		doors.enabled = false
	
	if after_safety_map:
		after_safety_map.enabled = true
	
	player.current_camera_type = "free"
	player.forced_position = null
	player.Camera.set_as_top_level(false)
	player.Camera.position = Vector2.ZERO
	
	if is_instance_valid(arena_parent):
		arena_parent.queue_free()
	
	if after_audio_path:
		if Global.map_holder.audio_path != after_audio_path:
			Global.map_holder.new_audio(after_audio_path)
	
	
	arena_won.emit(arena_parent)


func spawn_wave():
	if spawning_wave:
		return
	spawning_wave = true
	
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
					spawner,
					extra
				)
	
	spawning_wave = false






#region enemy spawning
func spawn_enemy(enemy_scene: PackedScene, spawn_node: Node2D, extra := {}) -> void:
	
	await get_tree().create_timer(0.5).timeout
	
	var enemy := enemy_scene.instantiate()
	
	
	for key in extra:
		enemy.set(key, extra[key])
	
	
	enemy.start_active = false
	spawn_node.call_deferred("add_child", enemy)
	
	enemy.killed.connect(_on_enemy_killed)
	alive_enemies += 1
	
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
		if is_instance_valid(enemy) and enemy.has_method("activate"):
			enemy.activate()
)
#endregion


#region sfx
func play_sfx(path: String):
	var audio_player := AudioStreamPlayer.new()
	audio_player.stream = load(path)
	audio_player.bus = "SFX"
	add_child(audio_player)
	audio_player.play()
	audio_player.finished.connect(audio_player.queue_free)
#endregion
