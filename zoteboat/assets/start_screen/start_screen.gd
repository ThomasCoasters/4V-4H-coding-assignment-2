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
@onready var volume: Button = $settings/volume
@onready var exit: Button = $settings/exit

@onready var delete_save: Button = $extra/delete_save
@onready var exit_extra: Button = $extra/exit

@onready var save_yes: Button = $"reset_save/save-yes"
@onready var save_no: Button = $"reset_save/save-no"

@onready var left_arrow: AnimatedSprite2D = $left_arrow
@onready var right_arrow: AnimatedSprite2D = $right_arrow

@export var arrow_offset: Vector2 = Vector2(20, 0)

@onready var basic_buttons: VBoxContainer = $"basic buttons"
@onready var quit_game_buttons: VBoxContainer = $"quit game"
@onready var settings: VBoxContainer = $settings
@onready var extra_buttons: VBoxContainer = $extra
@onready var reset_save: VBoxContainer = $reset_save


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

var volume_states = ["Off", "Low", "Normal", "High", "way to high"]
var volume_values = {
	"Off": -80,
	"Low": -10,
	"Normal": 0,
	"High": +10,
	"way to high": +20,
}
var current_volume_index: int = 2

func _ready() -> void:
	current_rumble_index = SaveLoad.contents_to_save.rumble
	current_screen_shake_index = SaveLoad.contents_to_save.screen_shake
	current_volume_index = SaveLoad.contents_to_save.volume
	
	
	var rumble_state_name = rumble_states[current_rumble_index]
	rumble.text = "Rumble: " + rumble_state_name
	Global.player.controller_rumble_mult = rumble_values[rumble_state_name]
	
	var screen_shake_state_name = screen_shake_states[current_screen_shake_index]
	screen_shake.text = "Screen Shake: " + screen_shake_state_name
	Global.player.screen_shake_mult = screen_shake_values[screen_shake_state_name]
	
	var volume_state_name = volume_states[current_volume_index]
	volume.text = "Volume: " + volume_state_name
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, volume_values[volume_state_name])
	
	containers = [basic_buttons, quit_game_buttons, settings, extra_buttons, reset_save]
	
	for contain in containers:
		hide_menu(contain)
	show_menu(basic_buttons)
	
	buttons = [start, options, extra, quit_game, quit_yes, quit_no, rumble, screen_shake, volume, exit, delete_save, exit_extra, save_yes, save_no]
	
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
			
			controller_active = true
		
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
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
	current_volume_index += 1
	if current_volume_index >= volume_states.size():
		current_volume_index = 0
	
	var state_name = volume_states[current_volume_index]
	
	volume.text = "Volume: " + state_name
	
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, volume_values[state_name])
	
	ui_button_confirm.play()
	
	SaveLoad.contents_to_save.volume = current_volume_index
	SaveLoad._save()


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
