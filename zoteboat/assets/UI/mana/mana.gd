extends Control

@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar
const EMPTY_SOUL = preload("uid://0fxi6j4327ie")
const MANA_FULL = preload("uid://1wdgjn2qcw0l")

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	
	_on_mana_change(0)
	
	Global.player.player_mana_changed.connect(_on_mana_change)


func _on_mana_change(new_mana) -> void:
	texture_progress_bar.value = new_mana
