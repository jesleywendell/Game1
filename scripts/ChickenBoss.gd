extends "res://scripts/GalinhaPodre.gd"

signal boss_triggered
signal boss_defeated

const BOSS_RADIUS    := 22.0
const TRIGGER_RADIUS := 120.0

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
	ProgressionManager.add_fragments(50)
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
		draw_circle(Vector2.ZERO, BOSS_RADIUS, Color(1.0, 0.85, 0.1, 0.95))
		draw_arc(Vector2.ZERO, BOSS_RADIUS + 4.0, 0.0, TAU, 32, Color(1.0, 0.6, 0.0, 0.6), 2.0)
	if is_dead or current_health >= MAX_HEALTH:
		return
	var x := -BAR_W / 2.0
	draw_rect(Rect2(x, BAR_Y, BAR_W, BAR_H), Color(0.15, 0.0, 0.0, 0.85))
	var fill := BAR_W * (current_health / MAX_HEALTH)
	draw_rect(Rect2(x, BAR_Y, fill, BAR_H), Color(1.0, 0.7, 0.0, 1.0))
