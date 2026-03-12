extends Node2D

var entered: bool = false

var current_anim: String

enum ANIM_PRIORITY {
	IDLE,
	TURN,
	TALK
}

@onready var miner_idle_hum: AudioStreamPlayer = $audio/MinerIdleHum
@onready var myla_pickaxe_1: AudioStreamPlayer = $audio/MylaPickaxe1
@onready var myla_pickaxe_2: AudioStreamPlayer = $audio/MylaPickaxe2
var pickaxe_sfx: Array[AudioStreamPlayer] = []
var mine_sfx_played: bool = false
@onready var miner_01: AudioStreamPlayer = $audio/Miner01
@onready var miner_02: AudioStreamPlayer = $audio/Miner02
@onready var miner_03: AudioStreamPlayer = $audio/Miner03
@onready var miner_04: AudioStreamPlayer = $audio/Miner04
@onready var miner_05: AudioStreamPlayer = $audio/Miner05
var talk_sfx: Array[AudioStreamPlayer] = []

var current_anim_priority: int = 0

var facing_dir: int = -1 # -1 = left           1 = right

@export var dialogue: String = "lantern_tip"
@export var enable_repeat_dialogue: bool = false
@export var repeat_dialogue: String = "lantern_tip_repeat"

func _ready() -> void:
	pickaxe_sfx = [myla_pickaxe_1, myla_pickaxe_2]
	talk_sfx = [miner_01, miner_02, miner_03, miner_04, miner_05]
	
	$Sprite2D.animation_finished.connect(_on_animation_finished)
	
	$Sprite2D2.visible = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	entered = true
	$Sprite2D2.visible = true
	
	await get_tree().create_timer(4.0).timeout



func _on_area_2d_body_exited(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	entered = false
	$Sprite2D2.visible = false
	
	current_anim_priority = 0
	play_anim("talk(end)", ANIM_PRIORITY.TALK)


func _physics_process(_delta: float) -> void:
	play_anim("idle", ANIM_PRIORITY.IDLE)
	
	if current_anim == "idle":
		if !miner_idle_hum.playing:
			miner_idle_hum.play()
		if ($Sprite2D.frame == 5 || $Sprite2D.frame == 6) && !mine_sfx_played:
			mine_sfx_played = true
			pickaxe_sfx.pick_random().play()
		
		if !($Sprite2D.frame == 5 || $Sprite2D.frame == 6):
			mine_sfx_played = false
			
	
	if Global.player.direction.y == 1 && !Global.player.moving.active:
		Global.dialogue.start(dialogue)
		
		play_anim("talk(start)", ANIM_PRIORITY.TALK)
		talk_sfx.pick_random().play()
		miner_idle_hum.stop()
		
		if enable_repeat_dialogue:
			dialogue = repeat_dialogue




#region animations
func play_anim(anim_name: String = "idle", priority: int = 0):
	if priority < current_anim_priority:
		return
	
	current_anim_priority = priority
	
	
	current_anim = anim_name
	
	$Sprite2D.play(anim_name)

func _on_animation_finished():
	current_anim_priority = 0
	
	if current_anim == "talk(start)":
		play_anim("talk", ANIM_PRIORITY.TALK)
#endregion
