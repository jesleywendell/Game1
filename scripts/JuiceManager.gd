extends Node

var _hitstop_timer: Timer
var _noise: FastNoiseLite
var _trauma: float = 0.0
var _noise_time: float = 0.0
const MAX_OFFSET := Vector2(14.0, 10.0)

func _ready() -> void:
	_hitstop_timer = Timer.new()
	_hitstop_timer.one_shot = true
	_hitstop_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_hitstop_timer.timeout.connect(_on_hitstop_end)
	add_child(_hitstop_timer)

	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 0.5

func _process(delta: float) -> void:
	if _trauma > 0.0:
		_trauma = maxf(_trauma - delta * 1.8, 0.0)
		_noise_time += delta * 60.0
		var cam: Camera2D = get_viewport().get_camera_2d()
		if cam:
			var shake := _trauma * _trauma
			cam.offset.x = MAX_OFFSET.x * shake * _noise.get_noise_2d(_noise_time, 0.0)
			cam.offset.y = MAX_OFFSET.y * shake * _noise.get_noise_2d(0.0, _noise_time)
	else:
		var cam: Camera2D = get_viewport().get_camera_2d()
		if cam:
			cam.offset = Vector2.ZERO

func add_trauma(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)

func apply_hitstop(duration: float = 0.06, scale: float = 0.04) -> void:
	Engine.time_scale = scale
	_hitstop_timer.start(duration * scale)

func _on_hitstop_end() -> void:
	Engine.time_scale = 1.0

func spawn_blood(pos: Vector2, parent: Node) -> void:
	var p := CPUParticles2D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.92
	p.lifetime = 0.35
	p.amount = 10
	p.direction = Vector2.UP
	p.spread = 50.0
	p.gravity = Vector2(0, 120)
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 180.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(0.55, 0.0, 0.0, 1.0)
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(0.5, false).timeout.connect(p.queue_free)

func spawn_damage_number(amount: float, pos: Vector2, parent: Node, is_player_hit: bool = false) -> void:
	var label := Label.new()
	label.text = str(int(amount))
	label.z_index = 100
	label.modulate = Color(1.0, 0.25, 0.25) if is_player_hit else Color(1.0, 0.85, 0.2)
	if not is_player_hit:
		label.scale = Vector2(0.85, 0.85)
	parent.add_child(label)
	label.global_position = pos + Vector2(randf_range(-8.0, 8.0), -20.0)
	var travel := Vector2(randf_range(-12.0, 12.0), -38.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + travel, 0.55).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_property(label, "modulate:a", 0.0, 0.55).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)
