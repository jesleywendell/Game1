extends Area2D

const MAX_RADIUS := 280.0
const GROW_TIME  := 1.5
const HOLD_TIME  := 1.5
const FADE_TIME  := 0.5

var _radius       := 0.0
var _phase        := "grow"
var _phase_timer  := 0.0
var _alpha        := 0.7
var _seized       : Array = []

func _ready() -> void:
	var col    := CollisionShape2D.new()
	var shape  := CircleShape2D.new()
	shape.radius = 1.0
	col.shape  = shape
	add_child(col)
	collision_layer = 0
	collision_mask  = 0xFFFFFFFF
	body_entered.connect(_on_body_entered)
	z_index = 3

func _process(delta: float) -> void:
	_phase_timer += delta
	match _phase:
		"grow":
			_radius = MAX_RADIUS * minf(_phase_timer / GROW_TIME, 1.0)
			_alpha  = 0.7
			if _phase_timer >= GROW_TIME:
				_phase = "hold"
				_phase_timer = 0.0
		"hold":
			_alpha = 0.5 + sin(_phase_timer * 6.0) * 0.15
			if _phase_timer >= HOLD_TIME:
				_phase = "fade"
				_phase_timer = 0.0
		"fade":
			_alpha = maxf(0.7 - (_phase_timer / FADE_TIME) * 0.7, 0.0)
			if _phase_timer >= FADE_TIME:
				queue_free()
				return
	var col := get_child(0) as CollisionShape2D
	if col and col.shape is CircleShape2D:
		(col.shape as CircleShape2D).radius = _radius
	queue_redraw()

func _draw() -> void:
	if _radius <= 0.0:
		return
	draw_circle(Vector2.ZERO, _radius, Color(0.6, 0.0, 0.0, _alpha * 0.25))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, Color(1.0, 0.1, 0.1, _alpha * 0.9), 3.0)
	draw_arc(Vector2.ZERO, _radius * 0.85, 0.0, TAU, 48, Color(0.8, 0.1, 0.1, _alpha * 0.5), 1.5)

func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_blood_seizure") and not _seized.has(body):
		_seized.append(body)
		body.apply_blood_seizure()
