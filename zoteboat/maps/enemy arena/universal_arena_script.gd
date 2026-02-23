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

#region infinite arena
const ENEMY_DATA := {
	"dvd": {
		"scene": DVD_ENEMY,
		"value": 0.5,
	},
	"aspid": {
		"scene": ASPID_ENEMY,
		"value": 2,
	},
	"squash": {
		"scene": SQUASH_ENEMY,
		"value": 3,
	},
	"peashooter": {
		"scene": PEASHOOTER_ENEMY,
		"value": 1,
	},
	"primal": {
		"scene": PRIMAL_ASPID,
		"value": 7,
	},
	"grimm_attack": {
		"scene": GRIMMKIN_BULLETS,
		"value": 4,
	},
	"grimm_circle": {
		"scene": GRIMMKIN_CIRCLE,
		"value": 5,
	},
	"jevil_phase_3": {
		"scene": JEVIL_BOSS,
		"value": 8,
	},
	"jevil_normal": {
		"scene": JEVIL_BOSS,
		"value": 25,
	},
	"jevil_phase_2": {
		"scene": JEVIL_BOSS,
		"value": 20,
	},
}


var enemy_extras := {
	"aspid": {
		"forced": {
			"start_attacking": true,
		},
	},
	"primal": {
		"forced": {
			"start_attacking": true,
		},
	},
	"grimm_attack": {
		"forced": {
			"start_attacking": true,
		},
	},
	"grimm_circle": {
		"forced": {
			"start_attacking": true,
		},
	},
	"dvd": {
		"random": {
			"angle": func(): return randf_range(0.0, 360.0),
		},
	},
	"peashooter": {
		"random": {
			"face_left": func(): return randf() < 0.5,
		},
	},
	"jevil_phase_3": {
		"forced": {
			"begin_phase": 3,
		},
	},
	"jevil_normal": {
		"forced": {
			"damage_mult": 4,
		},
	},
	"jevil_phase_2": {
		"forced": {
			"begin_phase": 2,
			"damage_mult": 3,
		},
	},
}
#endregion

#endregion


signal arena_won(node: Node)

var arena_parent: Node = null

@export_group("audio paths")
@export var arena_audio_path: String
@export var win_sfx_audio_path: String = "res://maps/enemy arena/Boss Defeat.wav"
@export var after_audio_path: String

@export_group("slowdown")
@export var enable_slowdown: bool = true
@export_range(0.0, 5.0, 0.01) var slowdown_time: float = 3.0
@export_range(0.0, 1.0, 0.01) var slowdown_speed: float = 0.15

@export_group("funni stuff")
@export var infinite_random_arena: bool = false
@export var base_wave_value := 0
@export var wave_value_growth := 2
@export var max_enemies_per_wave := 6


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
	
	if arena_bounds:
		Global.map.arena_bounds = arena_bounds
	
	player = Global.player
	
	for wave_number in range(wave_holder.get_child_count()):
		wave_to_node[wave_number+1] = wave_holder.get_child(wave_number)
	
	


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
	
	
	
	
	if infinite_random_arena:
		for spawner in wave_to_node[current_wave].get_children():
			
			if "camera_mode" in spawner.name:
				for mode in spawner.get_children():
					player.current_camera_type = mode.name

func finish_arena():
	Engine.time_scale = slowdown_speed
	
	if win_sfx_audio_path:
		set_as_top_level(true)
		play_sfx(win_sfx_audio_path)
	
	if arena_audio_path:
		Global.map_holder.audio.stop()
	
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
	
	if infinite_random_arena:
		var wave_text: String = "Wave: " + str(current_wave)
		Global.Name_text.reveal_text(wave_text, 0.3)
		
		var budget := get_wave_value(current_wave)
		var enemies := generate_wave_enemies(budget)
		
		for enemy_key in enemies:
			var enemy_scene = ENEMY_DATA[enemy_key].scene
			var pos := get_random_position_in_arena()
			var extras := build_enemy_extras(enemy_key)
			
			spawn_enemy_at_position(enemy_scene, pos, extras)
		
		await get_tree().create_timer(1.0).timeout
		Global.Name_text.remove_text(0.3)
		
		spawning_wave = false
		return
	
	
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
	get_tree().current_scene.add_child(audio_player)
	audio_player.play()
	audio_player.finished.connect(audio_player.queue_free)
#endregion



#region infinite arena
func get_wave_value(wave: int) -> int:
	return base_wave_value + wave * wave_value_growth

func generate_wave_enemies(budget: float) -> Array:
	var result := []
	var remaining := budget
	
	var keys := ENEMY_DATA.keys()
	keys.shuffle()
	
	while remaining > 0.0 and result.size() < max_enemies_per_wave:
		var valid := []
		
		for key in keys:
			if ENEMY_DATA[key]["value"] <= remaining:
				valid.append(key)
		
		if valid.is_empty():
			break
		
		var chosen = valid.pick_random()
		result.append(chosen)
		remaining -= ENEMY_DATA[chosen]["value"]
	
	return result


func get_random_position_in_arena() -> Vector2:
	var shape := arena_bounds.shape
	if shape is RectangleShape2D:
		var extents = shape.extents
		var center := arena_bounds.global_position
		
		return Vector2(
			randf_range(center.x - extents.x, center.x + extents.x),
			randf_range(center.y - extents.y, center.y + extents.y)
		)
	
	return arena_bounds.global_position

func spawn_enemy_at_position(enemy_scene: PackedScene, pos: Vector2, extra := {}):
	await get_tree().create_timer(1.3).timeout
	
	var enemy := enemy_scene.instantiate()
	enemy.global_position = pos
	
	for k in extra:
		enemy.set(k, extra[k])
	
	enemy.start_active = false
	add_child(enemy)
	enemy.killed.connect(_on_enemy_killed)
	alive_enemies += 1
	
	fade_in_enemy(enemy, 0.7)


func build_enemy_extras(enemy_key: String, manual := {}) -> Dictionary:
	var result := {}
	
	if enemy_extras.has(enemy_key):
		var data = enemy_extras[enemy_key]
		
		if data.has("forced"):
			for k in data.forced:
				result[k] = data.forced[k]
		
		if data.has("random"):
			for k in data.random:
				result[k] = data.random[k].call()
	
	for k in manual:
		result[k] = manual[k]
	
	return result

#endregion
