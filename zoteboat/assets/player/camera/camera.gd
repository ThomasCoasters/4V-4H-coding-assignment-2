extends Camera2D

var base_offset := Vector2(0, -220)

var shake_intensity := 0.0
var active_shake_time := 0.0
var shake_decay := 0.0
var shake_time := 0.0
var shake_time_speed := 20.0

var noise := FastNoiseLite.new()

var last_time := 0.0


func _ready():
	last_time = Time.get_ticks_usec()
	
	offset = base_offset

func _process(_delta):
	update_camera()


func update_camera():
	var now = Time.get_ticks_usec()
	var real_delta = (now - last_time) / 1_000_000.0
	last_time = now
	
	
	if active_shake_time > 0:
		shake_time -= real_delta * shake_time_speed
		active_shake_time -= real_delta
		
		var shake_offset = Vector2(
			noise.get_noise_2d(shake_time, 0),
			noise.get_noise_2d(0, shake_time)
		) * shake_intensity
		
		offset = base_offset + shake_offset
		
		shake_intensity = max(shake_intensity - shake_decay * real_delta, 0)
	else:
		offset = offset.lerp(base_offset, 10.5 * real_delta)

func screen_shake(intensity: float, time: float):
	noise.seed = randi()
	noise.frequency = 2.0
	
	shake_intensity = intensity
	active_shake_time = time
	shake_time = 0.0
