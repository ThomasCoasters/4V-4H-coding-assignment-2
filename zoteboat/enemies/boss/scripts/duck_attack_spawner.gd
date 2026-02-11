extends Node2D


@export var active_time: float = 7.0
@export var spawn_cooldown: float = 1.2

const DUCK_ATTACK = preload("uid://bo0lsftpy3omb")

@onready var spawn_timer: Timer = $spawn_timer
@onready var active_timer: Timer = $active_timer

var spawning: bool = false
var spawn_offset_x

@export var duck_speed: float = 300.0
@export var duck_vertical_speed: float = 200.0

func _ready() -> void:
	spawn_timer.wait_time = spawn_cooldown
	active_timer.wait_time = active_time

func start_spawning():
	spawn_timer.stop()
	active_timer.stop()
	
	spawn_timer.wait_time = spawn_cooldown
	active_timer.wait_time = active_time
	
	spawn_timer.start()
	active_timer.start()
	spawn_duck()
	
	spawning = true


func spawn_duck():
	var ducki = DUCK_ATTACK.instantiate()
	ducki.speed = duck_speed
	ducki.vertical_speed = duck_vertical_speed
	get_tree().current_scene.add_child(ducki)
	ducki.global_position = Vector2(global_position.x + spawn_offset_x, global_position.y + ducki.bottom_out_view_px)


func _on_spawn_timer_timeout() -> void:
	if spawning:
		spawn_duck()
		spawn_timer.start()


func _on_active_timer_timeout() -> void:
	spawning = false
