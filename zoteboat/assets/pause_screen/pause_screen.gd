extends CanvasLayer

var loading: bool = false

@onready var start: Button = $"basic buttons/start"
@onready var options: Button = $"basic buttons/Options"
@onready var quit_game: Button = $"basic buttons/Quit Game"

@onready var quit_yes: Button = $"quit game/Quit-yes"
@onready var quit_no: Button = $"quit game/Quit-no"

@onready var rumble: Button = $settings/rumble
@onready var screen_shake: Button = $settings/screen_shake
@onready var volume: Button = $settings/audio
@onready var exit: Button = $settings/exit

@onready var left_arrow: AnimatedSprite2D = $left_arrow
@onready var right_arrow: AnimatedSprite2D = $right_arrow

@export var arrow_offset: Vector2 = Vector2(25, -2)

@onready var basic_buttons: VBoxContainer = $"basic buttons"
@onready var quit_game_buttons: VBoxContainer = $"quit game"
@onready var settings: VBoxContainer = $settings
@onready var volume_settings: VBoxContainer = $volume_settings

@onready var master_volume: Button = $volume_settings/master_volume
@onready var sound_volume: Button = $volume_settings/sound_volume
@onready var music_volume: Button = $volume_settings/music_volume
@onready var exit_audio: Button = $volume_settings/exit_audio

@onready var title: AudioStreamPlayer = $audio/Title
@onready var ui_button_cancel: AudioStreamPlayer = $audio/UiButtonCancel
@onready var ui_button_confirm: AudioStreamPlayer = $audio/UiButtonConfirm
@onready var ui_change_selection: AudioStreamPlayer = $audio/UiChangeSelection


var shown_menu

var buttons: Array[Button]
var containers: Array[VBoxContainer]
var focused_index := 0

var controller_active: bool = false

var rumble_states = ["Off", "Low", "Normal"]
var rumble_values = {
	"Off": 0.0,
	"Low": 0.5,
	"Normal": 1.0,
}
var current_rumble_index: int = 2

var screen_shake_states = ["Off", "Low", "Normal", "High", "Highest", "yes"]
var screen_shake_values = {
	"Off": 0.0,
	"Low": 0.5,
	"Normal": 1.0,
	"High": 1.5,
	"Highest": 2.5,
	"yes": 20
}
var current_screen_shake_index: int = 2

var volume_states = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
var volume_values = {
	"0": -80,
	"1": -18,
	"2": -16,
	"3": -14,
	"4": -12,
	"5": -10,
	"6": -8,
	"7": -6,
	"8": -4,
	"9": -2,
	"10": 0,
}
var current_master_volume_index: int = 10
var current_sound_volume_index: int = 10
var current_music_volume_index: int = 10

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	Global.map_holder.process_mode = Node.PROCESS_MODE_DISABLED
	
	current_rumble_index = index_from_value(
		Global.player.controller_rumble_mult,
		rumble_states,
		rumble_values
	)
	
	current_screen_shake_index = index_from_value(
		Global.player.screen_shake_mult,
		screen_shake_states,
		screen_shake_values
	)
	
	var bus_index = AudioServer.get_bus_index("Master")
	current_master_volume_index = index_from_value(
		AudioServer.get_bus_volume_db(bus_index),
		volume_states,
		volume_values
	)
	bus_index = AudioServer.get_bus_index("SFX")
	current_sound_volume_index = index_from_value(
		AudioServer.get_bus_volume_db(bus_index),
		volume_states,
		volume_values
	)
	bus_index = AudioServer.get_bus_index("background")
	current_music_volume_index = index_from_value(
		AudioServer.get_bus_volume_db(bus_index),
		volume_states,
		volume_values
	)
	
	rumble.text = "Rumble: " + rumble_states[current_rumble_index]
	screen_shake.text = "Screen Shake: " + screen_shake_states[current_screen_shake_index]
	master_volume.text = "Master Volume: " + volume_states[current_master_volume_index]
	sound_volume.text = "Master Volume: " + volume_states[current_sound_volume_index]
	music_volume.text = "Master Volume: " + volume_states[current_music_volume_index]
	
	
	containers = [basic_buttons, quit_game_buttons, settings, volume_settings]
	
	for contain in containers:
		hide_menu(contain)
	show_menu(basic_buttons)
	
	buttons = [start, options, quit_game, quit_yes, quit_no, rumble, screen_shake, volume, exit, master_volume, music_volume, sound_volume, exit_audio]
	
	for button in buttons:
		button.mouse_entered.connect(_on_hover.bind(button))
		button.focus_entered.connect(_on_hover.bind(button))
		button.mouse_exited.connect(_on_hover_exited)
		button.focus_exited.connect(_on_hover_exited)
	
	title.play()



func _unhandled_input(event: InputEvent) -> void:
	if loading:
		return
	
	
	if event.is_action_pressed("down") or event.is_action_pressed("up"):
		if not controller_active:
			match shown_menu:
				basic_buttons:
					start.grab_focus()
				quit_game_buttons:
					quit_yes.grab_focus()
				settings:
					rumble.grab_focus()
				volume_settings:
					master_volume.grab_focus()
			
			controller_active = true
		
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	elif event.is_action_pressed("ui_cancel"):
		await get_tree().physics_frame
		match shown_menu:
			basic_buttons:
				_on_start_pressed()
			quit_game_buttons:
				_on_quitno_pressed()
			settings:
				_on_exit_pressed()
			volume_settings:
				_on_exit_audio_pressed()
	
	elif event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		controller_active = false
		
		for button in buttons:
			button.release_focus()

func _on_hover(button: Button) -> void:
	if not is_instance_valid(button):
		return
	
	if not is_instance_valid(left_arrow) or not is_instance_valid(right_arrow):
		return
	
	var button_pos = button.global_position
	var button_size = button.size
	
	button.grab_focus()
	
	left_arrow.global_position = button_pos + Vector2(-arrow_offset.x, button_size.y / 2)
	right_arrow.global_position = button_pos + Vector2(button_size.x + arrow_offset.x, button_size.y / 2)
	
	left_arrow.play("in")
	right_arrow.play("in")
	
	ui_change_selection.play()





func _on_hover_exited():
	left_arrow.play_backwards("in")
	right_arrow.play_backwards("in")


func hide_menu(container: Control):
	container.visible = false
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.focus_mode = Control.FOCUS_NONE


func show_menu(container: Control):
	shown_menu = container
	controller_active = false
	container.visible = true
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	container.focus_mode = Control.FOCUS_ALL

func index_from_value(value: float, states: Array, values: Dictionary) -> int:
	for i in states.size():
		if is_equal_approx(values[states[i]], value):
			return i
	return 0



func _on_start_pressed() -> void:
	if loading:
		return
	
	await get_tree().physics_frame
	Global.map_holder.process_mode = Node.PROCESS_MODE_INHERIT
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	queue_free()


func _on_options_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(settings)
	
	ui_button_confirm.play()



func _on_quit_game_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(quit_game_buttons)
	
	
	
	ui_button_cancel.play()




func _on_quityes_pressed() -> void:
	ui_button_confirm.play()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()


func _on_quitno_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(basic_buttons)
	
	ui_button_cancel.play()



func _on_rumble_pressed() -> void:
	current_rumble_index += 1
	if current_rumble_index >= rumble_states.size():
		current_rumble_index = 0
	
	var state_name = rumble_states[current_rumble_index]
	
	rumble.text = "Rumble: " + state_name
	
	Global.player.controller_rumble_mult = rumble_values[state_name]
	
	ui_button_confirm.play()
	
	SaveLoad.contents_to_save.rumble = current_rumble_index
	SaveLoad._save()

func _on_screen_shake_pressed() -> void:
	current_screen_shake_index += 1
	if current_screen_shake_index >= screen_shake_states.size():
		current_screen_shake_index = 0
	
	var state_name = screen_shake_states[current_screen_shake_index]
	
	screen_shake.text = "Screen Shake: " + state_name
	
	Global.player.screen_shake_mult = screen_shake_values[state_name]
	
	ui_button_confirm.play()
	
	SaveLoad.contents_to_save.screen_shake = current_screen_shake_index
	SaveLoad._save()

func _on_exit_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(basic_buttons)
	
	ui_button_cancel.play()


func _on_master_volume_pressed() -> void:
	current_master_volume_index += 1
	if current_master_volume_index >= volume_states.size():
		current_master_volume_index = 0
	
	var state_name = volume_states[current_master_volume_index]
	
	master_volume.text = "Master Volume: " + state_name
	
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, volume_values[state_name])
	
	ui_button_confirm.play()
	
	SaveLoad.contents_to_save.master_volume = current_master_volume_index
	SaveLoad._save()


func _on_sound_volume_pressed() -> void:
	current_sound_volume_index += 1
	if current_sound_volume_index >= volume_states.size():
		current_sound_volume_index = 0
	
	var state_name = volume_states[current_sound_volume_index]
	
	sound_volume.text = "Sound Volume: " + state_name
	
	var bus_index = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus_index, volume_values[state_name])
	
	ui_button_confirm.play()
	
	SaveLoad.contents_to_save.sound_volume = current_sound_volume_index
	SaveLoad._save()


func _on_music_volume_pressed() -> void:
	current_music_volume_index += 1
	if current_music_volume_index >= volume_states.size():
		current_music_volume_index = 0
	
	var state_name = volume_states[current_music_volume_index]
	
	music_volume.text = "Music Volume: " + state_name
	
	var bus_index = AudioServer.get_bus_index("background")
	AudioServer.set_bus_volume_db(bus_index, volume_values[state_name])
	
	ui_button_confirm.play()
	
	SaveLoad.contents_to_save.music_volume = current_music_volume_index
	SaveLoad._save()

func _on_exit_audio_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(settings)
	
	ui_button_cancel.play()

func _on_audio_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(volume_settings)
	
	ui_button_confirm.play()
