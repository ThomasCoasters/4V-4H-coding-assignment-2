extends CanvasLayer

var loading: bool = false

@onready var start: Button = $"basic buttons/start"
@onready var options: Button = $"basic buttons/Options"
@onready var quit_game: Button = $"basic buttons/Quit Game"

@onready var quit_yes: Button = $"quit game/Quit-yes"
@onready var quit_no: Button = $"quit game/Quit-no"

@onready var rumble: Button = $settings/rumble
@onready var screen_shake: Button = $settings/screen_shake
@onready var exit: Button = $settings/exit

@onready var left_arrow: AnimatedSprite2D = $left_arrow
@onready var right_arrow: AnimatedSprite2D = $right_arrow

@export var arrow_offset: Vector2 = Vector2(20, 0)

@onready var basic_buttons: VBoxContainer = $"basic buttons"
@onready var quit_game_buttons: VBoxContainer = $"quit game"
@onready var settings: VBoxContainer = $settings

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

var screen_shake_states = ["Off", "Low", "Normal", "High", "Highest"]
var screen_shake_values = {
	"Off": 0.0,
	"Low": 0.5,
	"Normal": 1.0,
	"High": 1.5,
	"Highest": 2.5
}
var current_screen_shake_index: int = 2


func _ready() -> void:
	rumble.text = "Rumble: " + rumble_states[current_rumble_index]
	
	
	containers = [basic_buttons, quit_game_buttons, settings]
	
	for contain in containers:
		hide_menu(contain)
	show_menu(basic_buttons)
	
	buttons = [start, options, quit_game, quit_yes, quit_no, rumble, screen_shake, exit]
	
	for button in buttons:
		button.mouse_entered.connect(_on_hover.bind(button))
		button.focus_entered.connect(_on_hover.bind(button))
		button.mouse_exited.connect(_on_hover_exited)
		button.focus_exited.connect(_on_hover_exited)

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
			
			controller_active = true
		
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		controller_active = false
		
		for button in buttons:
			button.release_focus()

func _on_hover(button: Button) -> void:
	var button_pos = button.global_position
	var button_size = button.size
	
	button.grab_focus.call_deferred()
	
	left_arrow.global_position = button_pos + Vector2(-arrow_offset.x, button_size.y / 2)
	right_arrow.global_position = button_pos + Vector2(button_size.x + arrow_offset.x, button_size.y / 2)
	
	left_arrow.play("in")
	right_arrow.play("in")




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
	
	loading = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	Global.map_holder.change_2d_scene(Global.map_holder.starting_map, "start")
	
	await get_tree().create_timer(0.5).timeout
	
	queue_free()


func _on_options_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(settings)



func _on_quit_game_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(quit_game_buttons)




func _on_quityes_pressed() -> void:
	get_tree().quit()


func _on_quitno_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(basic_buttons)



func _on_rumble_pressed() -> void:
	current_rumble_index += 1
	if current_rumble_index >= rumble_states.size():
		current_rumble_index = 0
	
	var state_name = rumble_states[current_rumble_index]
	
	rumble.text = "Rumble: " + state_name
	
	Global.player.controller_rumble_mult = rumble_values[state_name]


func _on_screen_shake_pressed() -> void:
	current_screen_shake_index += 1
	if current_screen_shake_index >= screen_shake_states.size():
		current_screen_shake_index = 0
	
	var state_name = screen_shake_states[current_screen_shake_index]
	
	screen_shake.text = "Screen Shake: " + state_name
	
	Global.player.screen_shake_mult = screen_shake_values[state_name]


func _on_exit_pressed() -> void:
	for contain in containers:
		hide_menu(contain)
	show_menu(basic_buttons)
