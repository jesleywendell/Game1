extends Area2D

var DAMAGE          := 10.0
var DAMAGE_INTERVAL := 1.0
var MAX_HEALTH      := 60.0
const MOVE_SPEED      := 60.0
const DETECT_RANGE    := 15000.0
const STOP_RANGE      := 20.0
const MAP_X := Vector2(-1600.0, 2080.0)
const MAP_Y := Vector2(8.0, 1848.0)
const FRAME_W         := 41
const FRAME_H         := 25
const IDLE_FRAMES     := 7

const BAR_W := 60.0
const BAR_H := 6.0
const BAR_Y := 42.0   # abaixo do sprite

var current_health  := MAX_HEALTH
var is_dead         := false
var xp_reward       := 25.0
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
	var player_node: Node2D = get_tree().get_first_node_in_group("player")
	if player_node == null or is_dead:
		return
	var dist := global_position.distance_to(player_node.global_position)
	if dist < DETECT_RANGE and dist > STOP_RANGE:
		var dir := (player_node.global_position - global_position).normalized()
		position += dir * MOVE_SPEED * delta
	position.x = clampf(position.x, MAP_X.x, MAP_X.y)
	position.y = clampf(position.y, MAP_Y.x, MAP_Y.y)
	if _player == null:
		return
	_damage_timer -= delta
	if _damage_timer <= 0.0:
		_damage_timer = DAMAGE_INTERVAL
		_player.take_damage(DAMAGE, Vector2.ZERO)
	z_index = int(global_position.y / 8.0)

func take_damage(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	current_health = maxf(current_health - amount, 0.0)
	queue_redraw()
	_flash_hit()
	JuiceManager.spawn_blood(global_position, get_parent())
	JuiceManager.spawn_damage_number(amount, global_position, get_parent())
	if amount >= 20.0:
		JuiceManager.apply_hitstop(0.06)
		JuiceManager.add_trauma(0.25)
	if direction != Vector2.ZERO:
		position += direction * 18.0
	if current_health <= 0.0:
		_die()

func _flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2.0, 0.4, 0.4, 1.0), 0.05)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

func receive_hit(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	take_damage(amount, direction)

func _die() -> void:
	is_dead = true
	_player = null
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	ProgressionManager.add_xp(xp_reward)
	ProgressionManager.add_fragments(randi_range(1, 3))
	JuiceManager.spawn_blood(global_position, get_parent())
	JuiceManager.apply_hitstop(0.08)
	JuiceManager.add_trauma(0.3)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func _draw() -> void:
	pass

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		_player = body
		_damage_timer = 0.0

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
