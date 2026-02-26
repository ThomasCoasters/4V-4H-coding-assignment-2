extends Control

@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar
const EMPTY_SOUL = preload("uid://0fxi6j4327ie")
const MANA_FULL = preload("uid://1wdgjn2qcw0l")

var wanted_value: float = 0.0

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	
	_on_mana_change(0)
	
	Global.player.player_mana_changed.connect(_on_mana_change)


func _on_mana_change(new_mana) -> void:
	wanted_value = new_mana


func _physics_process(delta: float) -> void:
	texture_progress_bar.value = move_toward(
		texture_progress_bar.value,
		wanted_value,
		40 * delta
	)
