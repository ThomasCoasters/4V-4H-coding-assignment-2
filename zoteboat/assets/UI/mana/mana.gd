extends Control

@onready var ball: TextureRect = $ball

const MANA_FULL = preload("uid://1wdgjn2qcw0l")
const EMPTY_SOUL = preload("uid://0fxi6j4327ie")

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	
	_on_mana_change(0)
	
	Global.player.player_mana_changed.connect(_on_mana_change)


func _on_mana_change(new_mana) -> void:
	if new_mana >= 33:
		ball.texture = MANA_FULL
	else:
		ball.texture = EMPTY_SOUL
