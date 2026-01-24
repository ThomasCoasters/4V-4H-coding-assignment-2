extends Camera2D

var normal_offset: Vector2 = Vector2(0, -100)

var shake_intensity := 0.0
var active_shake_time := 0.0
var shake_decay := 0.0
var shake_time := 0.0
var shake_time_speed := 20.0

var noise := FastNoiseLite.new()

var last_time := 0.0

var camera: Camera2D = self

func _ready():
	last_time = Time.get_ticks_usec()
	
	offset = normal_offset

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
		
		offset = shake_offset + normal_offset
		
		shake_intensity = max(shake_intensity - shake_decay * real_delta, 0)
	else:
		offset = lerp(offset, normal_offset, 10.5 * real_delta)

func screen_shake(intensity: float, time: float):
	noise.seed = randi()
	noise.frequency = 2.0
	
	shake_intensity = intensity
	active_shake_time = time
	shake_time = 0.0

func stop_shake():
	active_shake_time = -1


func setup_limits(ground: TileMapLayer):
	var used_rect = ground.get_used_rect()
	var cell_size: Vector2 = Vector2(ground.tile_set.tile_size) * ground.scale
	
	var margin_tiles := 1
	var margin = cell_size * margin_tiles
	
	var left   = used_rect.position.x * cell_size.x
	var top    = used_rect.position.y * cell_size.y
	var right  = (used_rect.position.x + used_rect.size.x) * cell_size.x
	var bottom = (used_rect.position.y + used_rect.size.y) * cell_size.y
	
	limit_left   = left   + margin.x - normal_offset.x
	limit_right  = right  - margin.x - normal_offset.x
	limit_top    = top    + margin.y - normal_offset.y
	limit_bottom = bottom - margin.y - normal_offset.y
