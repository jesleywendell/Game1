extends Area2D

const SPEED           := 145.0
const DAMAGE          := 10.0
const DAMAGE_INTERVAL := 0.85
const LIFETIME        := 20.0
const BODY_RADIUS     := 5.5
const WING_RADIUS     := 5.0
const MAX_HEALTH      := 15.0

var current_health := MAX_HEALTH
var is_dead        := false
var _damage_timer  := 0.0
var _life_timer    := LIFETIME
var _player: Node  = null
var _moving        := false
var _buzz_t        := 0.0
var _wing_alpha    := 0.45
var _hover_t       := 0.0
var _col: CollisionShape2D

func _ready() -> void:
	add_to_group("summoned_flies")

	var circle := CircleShape2D.new()
	circle.radius = BODY_RADIUS + 2.0
	_col = CollisionShape2D.new()
	_col.shape = circle
	_col.disabled = true
	add_child(_col)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Emerge from ground: start shrunken and semi-buried
	scale    = Vector2(0.2, 0.2)
	modulate = Color(1.0, 1.0, 1.0, 0.0)

	_spawn_ground_burst()

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale",      Vector2.ONE,            0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "modulate:a", 1.0,                    0.30)
	tw.tween_property(self, "position:y", position.y - 18.0,      0.45).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	tw.tween_callback(func():
		_col.disabled = false
		_moving = true
	)

func _spawn_ground_burst() -> void:
	var p                       := CPUParticles2D.new()
	p.emitting                   = true
	p.one_shot                   = true
	p.amount                     = 10
	p.lifetime                   = 0.5
	p.emission_shape             = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius     = 6.0
	p.direction                  = Vector2(0.0, -1.0)
	p.spread                     = 55.0
	p.gravity                    = Vector2(0.0, 80.0)
	p.initial_velocity_min       = 18.0
	p.initial_velocity_max       = 40.0
	p.scale_amount_min           = 2.0
	p.scale_amount_max           = 4.0
	p.color                      = Color(0.25, 0.15, 0.05, 0.85)
	p.z_index                    = z_index - 1
	add_child(p)
	get_tree().create_timer(0.7).timeout.connect(p.queue_free)

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return

	_buzz_t  += delta * 28.0
	_hover_t += delta
	_wing_alpha = 0.28 + 0.22 * abs(sin(_buzz_t))
	queue_redraw()

	if not _moving:
		return

	_life_timer -= delta
	if _life_timer <= 0.0:
		die_fade()
		return

	var player_node: Node2D = get_tree().get_first_node_in_group("player")
	if player_node == null:
		return

	var dir := (player_node.global_position - global_position).normalized()
	position += dir * SPEED * delta
	# Subtle vertical hover
	position.y += sin(_hover_t * 5.5) * 0.6

	if _player != null:
		_damage_timer -= delta
		if _damage_timer <= 0.0:
			_damage_timer = DAMAGE_INTERVAL
			_player.take_damage(DAMAGE, dir * 0.4)

	z_index = int(global_position.y / 8.0)

func _draw() -> void:
	# Wings — buzzling semi-transparent
	draw_circle(Vector2(-8.0, -5.0), WING_RADIUS, Color(0.82, 0.90, 0.96, _wing_alpha))
	draw_circle(Vector2( 8.0, -5.0), WING_RADIUS, Color(0.82, 0.90, 0.96, _wing_alpha))
	# Body
	draw_circle(Vector2(0.0,  2.0), BODY_RADIUS,       Color(0.12, 0.08, 0.02, 1.0))
	# Head
	draw_circle(Vector2(0.0, -4.0), BODY_RADIUS - 2.0, Color(0.20, 0.13, 0.04, 1.0))
	# Eyes
	draw_circle(Vector2(-1.8, -5.2), 1.1, Color(0.90, 0.05, 0.05, 1.0))
	draw_circle(Vector2( 1.8, -5.2), 1.1, Color(0.90, 0.05, 0.05, 1.0))

func take_damage(amount: float, _direction: Vector2 = Vector2.ZERO) -> void:
	if is_dead or not _moving:
		return
	current_health = maxf(current_health - amount, 0.0)
	JuiceManager.spawn_blood(global_position, get_parent())
	JuiceManager.spawn_damage_number(amount, global_position, get_parent())
	if current_health <= 0.0:
		die_fade()

func die_fade() -> void:
	if is_dead or not is_inside_tree():
		return
	is_dead = true
	_moving = false
	_player = null
	_col.set_deferred("disabled", true)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.30)
	tw.tween_callback(queue_free)

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		_player       = body
		_damage_timer = 0.0

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
