extends Area2D

const DAMAGE          := 10.0
const DAMAGE_INTERVAL := 1.0
const MAX_HEALTH      := 60.0
const FRAME_W         := 41
const FRAME_H         := 25
const IDLE_FRAMES     := 7

const BAR_W := 60.0
const BAR_H := 6.0
const BAR_Y := 42.0   # abaixo do sprite

var current_health  := MAX_HEALTH
var is_dead         := false
var _damage_timer   := 0.0
var _player: Node   = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_setup_animation()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _setup_animation() -> void:
	var frames := SpriteFrames.new()
	var tex: Texture2D = load("res://assets/critters/critters/boar/boar_SE_idle_strip.png")
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 8.0)
	frames.set_animation_loop("idle", true)
	for i in IDLE_FRAMES:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * FRAME_W, 0, FRAME_W, FRAME_H)
		frames.add_frame("idle", atlas)
	sprite.sprite_frames = frames
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if is_dead or _player == null:
		return
	_damage_timer -= delta
	if _damage_timer <= 0.0:
		_damage_timer = DAMAGE_INTERVAL
		_player.take_damage(DAMAGE, Vector2.ZERO)

func take_damage(amount: float, _direction: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	current_health = maxf(current_health - amount, 0.0)
	queue_redraw()
	if current_health <= 0.0:
		_die()

func receive_hit(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	take_damage(amount, direction)

func _die() -> void:
	is_dead = true
	_player = null
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func _draw() -> void:
	if is_dead or current_health >= MAX_HEALTH:
		return
	var x := -BAR_W / 2.0
	# fundo escuro
	draw_rect(Rect2(x, BAR_Y, BAR_W, BAR_H), Color(0.15, 0.0, 0.0, 0.85))
	# fill vermelho proporcional
	var fill := BAR_W * (current_health / MAX_HEALTH)
	draw_rect(Rect2(x, BAR_Y, fill, BAR_H), Color(0.9, 0.1, 0.1, 1.0))

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		_player = body
		_damage_timer = 0.0

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
