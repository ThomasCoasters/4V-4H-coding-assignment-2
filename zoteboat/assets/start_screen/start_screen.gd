extends CanvasLayer

var loading: bool = false

@onready var start: Button = $"basic buttons/start"
@onready var options: Button = $"basic buttons/Options"
@onready var quit_game: Button = $"basic buttons/Quit Game"
@onready var extra: Button = $"basic buttons/extra"

@onready var quit_yes: Button = $"quit game/Quit-yes"
@onready var quit_no: Button = $"quit game/Quit-no"

@onready var rumble: Button = $settings/rumble
@onready var screen_shake: Button = $settings/screen_shake
@onready var volume: Button = $settings/audio
@onready var exit: Button = $settings/exit

@onready var master_volume: Button = $volume_settings/master_volume
@onready var sound_volume: Button = $volume_settings/sound_volume
@onready var music_volume: Button = $volume_settings/music_volume
@onready var exit_audio: Button = $volume_settings/exit_audio

@onready var delete_save: Button = $extra/delete_save
@onready var variants: Button = $extra/variants
@onready var exit_extra: Button = $extra/exit

@onready var save_yes: Button = $"reset_save/save-yes"
@onready var save_no: Button = $"reset_save/save-no"

@onready var invis: Button = $variants/invis
@onready var unkillable: Button = $variants/unkillable
@onready var exit_variant: Button = $variants/exit_variant
@onready var perma_death: Button = $variants/perma_death

@onready var left_arrow: AnimatedSprite2D = $left_arrow
@onready var right_arrow: AnimatedSprite2D = $right_arrow

@export var arrow_offset: Vector2 = Vector2(25, -2)

@onready var basic_buttons: VBoxContainer = $"basic buttons"
@onready var quit_game_buttons: VBoxContainer = $"quit game"
@onready var settings: VBoxContainer = $settings
@onready var extra_buttons: VBoxContainer = $extra
@onready var reset_save: VBoxContainer = $reset_save
@onready var volume_settings: VBoxContainer = $volume_settings
@onready var variants_buttons: VBoxContainer = $variants


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

var variant_states = ["Off", "On"]
var variant_values = {
	"Off": false,
	"On": true
}
var current_invis_index: int = 0
var current_unkillable_index: int = 0
var current_permadeath_index: int = 0

func _ready() -> void:
	current_rumble_index = SaveLoad.contents_to_save.rumble
	current_screen_shake_index = SaveLoad.contents_to_save.screen_shake
	current_master_volume_index = SaveLoad.contents_to_save.master_volume
	current_sound_volume_index = SaveLoad.contents_to_save.sound_volume
	current_music_volume_index = SaveLoad.contents_to_save.music_volume
	current_unkillable_index = SaveLoad.contents_to_save.unkillable
	current_invis_index = SaveLoad.contents_to_save.invis
	current_permadeath_index = SaveLoad.contents_to_save.permadeath
	
	var rumble_state_name = rumble_states[current_rumble_index]
	rumble.text = "Rumble: " + rumble_state_name
	Global.player.controller_rumble_mult = rumble_values[rumble_state_name]
	
	var screen_shake_state_name = screen_shake_states[current_screen_shake_index]
	screen_shake.text = "Screen Shake: " + screen_shake_state_name
	Global.player.screen_shake_mult = screen_shake_values[screen_shake_state_name]
	
	var master_volume_state_name = volume_states[current_master_volume_index]
	master_volume.text = "Master Volume: " + master_volume_state_name
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, volume_values[master_volume_state_name])
	var sound_volume_state_name = volume_states[current_sound_volume_index]
	sound_volume.text = "Sound Volume: " + sound_volume_state_name
	bus_index = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus_index, volume_values[sound_volume_state_name])
	var music_volume_state_name = volume_states[current_music_volume_index]
	music_volume.text = "Music Volume: " + music_volume_state_name
	bus_index = AudioServer.get_bus_index("background")
	AudioServer.set_bus_volume_db(bus_index, volume_values[music_volume_state_name])
	
	var unkillable_state_name = variant_states[current_unkillable_index]
	unkillable.text = "Unkillable: " + unkillable_state_name
	Global.player.unkillable = variant_values[unkillable_state_name]
	
	var invis_state_name = variant_states[current_invis_index]
	invis.text = "Invisible Motion: " + invis_state_name
	Global.player.invis_moving = variant_values[invis_state_name]
	
	var perma_death_state_name = variant_states[current_permadeath_index]
	perma_death.text = "Permadeath (Resets Save):" + perma_death_state_name
	Global.player.permadeath = variant_values[perma_death_state_name]
	
	
	containers = [basic_buttons, quit_game_buttons, settings, extra_buttons, reset_save, volume_settings, variants_buttons]
	
	for contain in containers:
		hide_menu(contain)
	show_menu(basic_buttons)
	
	buttons = [start, options, extra, quit_game, quit_yes, quit_no, rumble, screen_shake, volume, exit, delete_save, unkillable, exit_extra, save_yes, save_no, exit_audio, music_volume, sound_volume, master_volume, variants, exit_variant, invis, perma_death]
	
	for button in buttons:
		button.mouse_entered.connect(_on_hover.bind(button))
		button.focus_entered.connect(_on_hover.bind(button))
		button.mouse_exited.connect(_on_hover_exited)
		button.focus_exited.connect(_on_hover_exited)
	
	title.play()



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("down") or event.is_action_pressed("up"):
		if not controller_active:
			match shown_menu:
				basic_buttons:
					start.grab_focus()
				quit_game_buttons:
					quit_yes.grab_focus()
				settings:
					rumble.grab_focus()
				extra_buttons:
					delete_save.grab_focus()
				reset_save:
					save_yes.grab_focus()
				volume_settings:
					master_volume.grab_focus()
				variants_buttons:
					invis.grab_focus()
			
			controller_active = true
		
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	if event.is_action_pressed("ui_cancel"):
		await get_tree().physics_frame
		match shown_menu:
			basic_buttons:
				_on_quit_game_pressed()
			quit_game_buttons:
				_on_quitno_pressed()
			settings:
				_on_exit_pressed()
			extra_buttons:
				_on_exit_pressed()
			reset_save:
				_on_saveno_pressed()
			volume_settings:
				_on_exit_audio_pressed()
			variants_buttons:
				_on_exit_variant_pressed()
	
	if event is InputEventMouseMotion:
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
	
	left_arrow.global_position = button_pos + Vector2(-arrow_offset.x, button_size.y / 2 + arrow_offset.y)
	right_arrow.global_position = button_pos + Vector2(button_size.x + arrow_offset.x, button_size.y / 2 + arrow_offset.y)
	
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



func _on_start_pressed() -> void:
	if loading:
		return
	
	SaveLoad._load()
	var room = SaveLoad.contents_to_save.starting_room
	var location = SaveLoad.contents_to_save.starting_location
	
	process_mode = Node.PROCESS_MODE_DISABLED
	ui_button_confirm.play()
	
	loading = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	Global.map_holder.change_2d_scene(room, location)
	
	await get_tree().create_timer(0.5).timeout
	
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

func _on_volume_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(volume_settings)
	
	ui_button_confirm.play()


func _on_exit_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(basic_buttons)
	
	ui_button_cancel.play()

func _on_extra_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(extra_buttons)
	
	ui_button_confirm.play()


func _on_delete_save_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(reset_save)
	
	ui_button_confirm.play()


func _on_saveyes_pressed() -> void:
	SaveLoad.reset_save()
	ui_button_confirm.play()
	
	await get_tree().create_timer(0.1).timeout
	get_tree().reload_current_scene()

func _on_saveno_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(extra_buttons)
	
	ui_button_cancel.play()


func _on_unkillable_pressed() -> void:
	current_unkillable_index += 1
	if current_unkillable_index >= variant_states.size():
		current_unkillable_index = 0
	
	var state_name = variant_states[current_unkillable_index]
	
	unkillable.text = "Unkillable: " + state_name
	
	Global.player.unkillable = variant_values[state_name]
	
	ui_button_confirm.play()
	
	SaveLoad.contents_to_save.unkillable = current_unkillable_index
	SaveLoad._save()


func _on_exit_audio_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(settings)
	
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


func _on_variants_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(variants_buttons)
	
	ui_button_cancel.play()


func _on_invis_pressed() -> void:
	current_invis_index += 1
	if current_invis_index >= variant_states.size():
		current_invis_index = 0
	
	var state_name = variant_states[current_invis_index]
	
	invis.text = "Invisible Motion: " + state_name
	
	Global.player.invis_moving = variant_values[state_name]
	
	ui_button_confirm.play()
	
	SaveLoad.contents_to_save.invis = current_invis_index
	SaveLoad._save()


func _on_exit_variant_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(extra_buttons)
	
	ui_button_cancel.play()


func _on_perma_death_pressed() -> void:
	current_permadeath_index += 1
	if current_permadeath_index >= variant_states.size():
		current_permadeath_index = 0
	
	var state_name = variant_states[current_permadeath_index]
	
	perma_death.text = "Permadeath (Resets Save): " + state_name
	
	Global.player.permadeath = variant_values[state_name]
	
	ui_button_confirm.play()
	
	SaveLoad.contents_to_save.permadeath = current_permadeath_index
	SaveLoad._save()
