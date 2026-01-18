extends Area2D

@export var doors: TileMapLayer

var arena_started: bool = false
var arena_finished: bool = false

@export var camera_pos: Node2D

var current_wave: int = 0

var wave_to_node : Dictionary = {}
@export var wave_holder : Node

var player

var alive_enemies := 0


#region enemy scenes
const TEST_DUMMY = preload("res://enemies/examples/test_dummy/test_dummy.tscn")
const DVD_ENEMY = preload("res://enemies/normal/dvd_logo/dvd_enemy.tscn")
const ASPID_ENEMY = preload("uid://3dmnl1rv4c6f")

const ENEMY_SCENES := {
	"dummy": TEST_DUMMY,
	"dvd": DVD_ENEMY,
	"aspid": ASPID_ENEMY,
}
#endregion


signal arena_won(node: Node)

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	
	for wave_number in range(wave_holder.get_child_count()):
		wave_to_node[wave_number+1] = wave_holder.get_child(wave_number)
	
	
	player = Global.player


func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player") || arena_started || arena_finished:
		return
	
	start_arena()


func start_arena():
	arena_started = true
	
	doors.enabled = true
	
	player.forced_position = camera_pos.position
	
	player.current_camera_type = "locked"
	
	spawn_wave()

func finish_arena():
	print("arena done")
	arena_started = false
	arena_finished = true
	
	doors.enabled = false
	
	player.current_camera_type = "free"
	
	
	arena_won.emit(self.get_parent())

func spawn_wave():
	current_wave += 1
	if !wave_to_node.has(current_wave):
		finish_arena()
		return
	
	for spawner in wave_to_node[current_wave].get_children():
		for key in ENEMY_SCENES:
			if key in spawner.name:
				spawn_enemy(ENEMY_SCENES[key], spawner.global_position)





#region enemy spawning
func spawn_enemy(enemy_scene: PackedScene, pos: Vector2) -> void:
	var enemy := enemy_scene.instantiate()
	
	get_tree().current_scene.call_deferred("add_child", enemy)
	enemy.global_position = pos
	
	alive_enemies += 1
	enemy.killed.connect(_on_enemy_killed)

func _on_enemy_killed(enemy):
	alive_enemies -= 1
	enemy.call_deferred("queue_free")
	
	if alive_enemies <= 0:
		print("wave done")
		spawn_wave()
#endregion
