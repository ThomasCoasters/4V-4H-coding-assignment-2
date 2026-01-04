extends Area2D

@export var doors: TileMapLayer

var arena_started: bool = false
var arena_finished: bool = false

@export var camera_pos: Node2D
const TEST_DUMMY = preload("res://enemies/normal/test_dummy/test_dummy.tscn")

var current_wave: int = 0

var wave_to_node : Dictionary = {}
@export var wave_holder : Node

var player

var alive_enemies := 0


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
	
	var spawn_node: Node = wave_to_node[current_wave]
	
	for spawner in spawn_node.get_children():
		if "dummy" in spawner.name:
			spawn_dummy(spawner.global_position)



func spawn_dummy(pos: Vector2) -> void:
	var dummy := TEST_DUMMY.instantiate()
	
	# Add to the same parent as the arena (or a dedicated enemy container)
	get_tree().current_scene.call_deferred("add_child", dummy)
	
	dummy.global_position = pos
	
	alive_enemies += 1
	
	dummy.killed.connect(_on_dummy_killed)


func _on_dummy_killed(dummy):
	alive_enemies -= 1
	dummy.call_deferred("queue_free")

	if alive_enemies <= 0:
		print("wave done")
		spawn_wave()
