extends "res://scripts/GalinhaPodre.gd"

signal boss_triggered
signal boss_defeated

const BOSS_RADIUS      := 22.0
const TRIGGER_RADIUS   := 120.0
const FRAGMENT_REWARD  := 50

var _triggered    := false
var _trigger_zone : Area2D

func _ready() -> void:
	MAX_HEALTH     = 200.0
	DAMAGE         = 25.0
	MOVE_SPEED     = 200.0
	xp_reward      = 80.0
	current_health = MAX_HEALTH
	super._ready()
	(_col_shape.shape as CircleShape2D).radius = BOSS_RADIUS
	_build_trigger_zone()
	set_physics_process(false)

func _build_trigger_zone() -> void:
	_trigger_zone = Area2D.new()
	_trigger_zone.collision_layer = 0
	_trigger_zone.collision_mask  = 1
	var tz_shape  := CollisionShape2D.new()
	var tz_circle := CircleShape2D.new()
	tz_circle.radius = TRIGGER_RADIUS
	tz_shape.shape   = tz_circle
	_trigger_zone.add_child(tz_shape)
	_trigger_zone.body_entered.connect(_on_trigger_entered)
	add_child(_trigger_zone)

func _on_trigger_entered(body: Node) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	_trigger_zone.set_deferred("monitoring", false)
	set_physics_process(true)
	boss_triggered.emit()

func _die() -> void:
	is_dead = true
	_player = null
	set_physics_process(false)
	_col_shape.set_deferred("disabled", true)
	ProgressionManager.add_xp(xp_reward)
	ProgressionManager.add_fragments(FRAGMENT_REWARD)
	AudioManager.play_sfx("enemy_die")
	JuiceManager.spawn_blood(global_position, get_parent())
	JuiceManager.apply_hitstop(0.12)
	JuiceManager.add_trauma(0.5)
	boss_defeated.emit()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _draw() -> void:
	if not is_dead:
		# Tail feathers
		draw_circle(Vector2(-22,4), 9.0, Color(0.62,0.72,0.55))
		draw_circle(Vector2(-24,10), 7.0, Color(0.55,0.65,0.48))
		draw_circle(Vector2(-20,-4), 8.0, Color(0.62,0.72,0.55))
		draw_circle(Vector2(-26,-1), 6.0, Color(0.50,0.60,0.44))
		# Body
		draw_circle(Vector2(0,5), 20.0, Color(0.78,0.88,0.72))
		# Wing
		draw_circle(Vector2(6,8), 12.0, Color(0.68,0.78,0.62))
		# Head
		draw_circle(Vector2(4,-13), 14.0, Color(0.78,0.88,0.72))
		# Comb — 4 bumps
		draw_circle(Vector2(-2,-25), 5.0, Color(0.85,0.15,0.10))
		draw_circle(Vector2(3,-27), 5.0, Color(0.85,0.15,0.10))
		draw_circle(Vector2(8,-26), 5.0, Color(0.85,0.15,0.10))
		draw_circle(Vector2(13,-24), 4.5, Color(0.85,0.15,0.10))
		# Wattle
		draw_circle(Vector2(14,-10), 4.5, Color(0.85,0.15,0.10))
		draw_circle(Vector2(16,-5), 3.5, Color(0.85,0.15,0.10))
		# Beak
		var beak := PackedVector2Array([Vector2(13,-17),Vector2(24,-11),Vector2(13,-6)])
		draw_colored_polygon(beak, Color(0.88,0.70,0.15))
		# Eye — angry
		draw_circle(Vector2(10,-14), 4.0, Color(0.05,0.05,0.05))
		draw_circle(Vector2(11,-15), 1.5, Color(0.9,0.1,0.1))
		draw_line(Vector2(6,-19), Vector2(14,-17), Color(0.20,0.22,0.18), 2.5)
		# Legs
		draw_line(Vector2(-3,23), Vector2(-6,36), Color(0.82,0.65,0.15), 3.5)
		draw_line(Vector2(6,23), Vector2(9,36), Color(0.82,0.65,0.15), 3.5)
		# Feet
		draw_line(Vector2(-6,36), Vector2(-14,40), Color(0.82,0.65,0.15), 2.5)
		draw_line(Vector2(-6,36), Vector2(-3,42), Color(0.82,0.65,0.15), 2.5)
		draw_line(Vector2(-6,36), Vector2(0,38), Color(0.82,0.65,0.15), 2.5)
		draw_line(Vector2(9,36), Vector2(2,40), Color(0.82,0.65,0.15), 2.5)
		draw_line(Vector2(9,36), Vector2(12,42), Color(0.82,0.65,0.15), 2.5)
		draw_line(Vector2(9,36), Vector2(15,38), Color(0.82,0.65,0.15), 2.5)
		# Boss aura ring
		draw_arc(Vector2.ZERO, BOSS_RADIUS + 6.0, 0.0, TAU, 48, Color(1.0,0.6,0.0,0.5), 2.5)
	if is_dead or current_health >= MAX_HEALTH:
		return
	var x := -BAR_W / 2.0
	draw_rect(Rect2(x, BAR_Y, BAR_W, BAR_H), Color(0.15,0.0,0.0,0.85))
	var fill := BAR_W * (current_health / MAX_HEALTH)
	draw_rect(Rect2(x, BAR_Y, fill, BAR_H), Color(1.0,0.7,0.0,1.0))
