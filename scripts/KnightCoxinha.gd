extends Area2D

var DAMAGE          := 20.0
var DAMAGE_INTERVAL := 1.0
var MAX_HEALTH      := 150.0
const MOVE_SPEED      := 55.0
const DETECT_RANGE    := 230.0
const STOP_RANGE      := 24.0

const FRAME_W := 68
const FRAME_H := 68
const COLS    := 6
const ROW_IDLE   := 0
const ROW_WALK   := 1
const ROW_ATTACK := 4
const ROW_SKILL  := 7

const SKILL_COOLDOWN  := 6.0
const SKILL_RANGE     := 210.0
const SKILL_DAMAGE    := 35.0
const CHARGE_SPEED    := 230.0
const CHARGE_DURATION := 0.38
const CHARGE_HIT_DIST := 64.0

const BAR_W := 70.0
const BAR_H := 6.0
const BAR_Y := 52.0

var current_health := MAX_HEALTH
var is_dead        := false
var xp_reward      := 65.0

var _damage_timer  := 0.0
var _skill_timer   := SKILL_COOLDOWN * 0.5
var _player: Node  = null

var _state        := "idle"
var _charge_dir   := Vector2.ZERO
var _charge_timer := 0.0
var _skill_active := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_setup_animation()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _setup_animation() -> void:
	var frames := SpriteFrames.new()
	var tex: Texture2D = load("res://assets/enemies/knight_coxinha/knight_coxinha.png")

	var single := {"idle": ROW_IDLE, "walk": ROW_WALK, "attack": ROW_ATTACK}
	for anim in single:
		frames.add_animation(anim)
		frames.set_animation_loop(anim, true)
		for i in COLS:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * FRAME_W, single[anim] * FRAME_H, FRAME_W, FRAME_H)
			frames.add_frame(anim, atlas)

	# Skill uses rows 7 + 8: windup buildup → golden-swirl release (12 frames total)
	frames.add_animation("skill")
	frames.set_animation_loop("skill", false)
	for skill_row in [ROW_SKILL, ROW_SKILL + 1]:
		for i in COLS:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * FRAME_W, skill_row * FRAME_H, FRAME_W, FRAME_H)
			frames.add_frame("skill", atlas)

	frames.set_animation_speed("idle",   8.0)
	frames.set_animation_speed("walk",  10.0)
	frames.set_animation_speed("attack", 14.0)
	frames.set_animation_speed("skill",  12.0)
	sprite.sprite_frames = frames
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var player_node: Node2D = get_tree().get_first_node_in_group("player")
	if player_node == null:
		return

	if _state == "skill_charge":
		_charge_timer -= delta
		position += _charge_dir * CHARGE_SPEED * delta
		_check_charge_hit(player_node)
		if _charge_timer <= 0.0:
			_end_skill()
		z_index = int(global_position.y / 8.0)
		return

	if _state == "skill_windup":
		z_index = int(global_position.y / 8.0)
		return

	_skill_timer -= delta
	var dist := global_position.distance_to(player_node.global_position)

	if _skill_timer <= 0.0 and dist < SKILL_RANGE:
		_start_skill(player_node)
		return

	if dist < DETECT_RANGE and dist > STOP_RANGE:
		var dir := (player_node.global_position - global_position).normalized()
		position += dir * MOVE_SPEED * delta
		sprite.flip_h = dir.x < 0
		_set_state("walk")
	else:
		_set_state("idle")

	if _player != null:
		_damage_timer -= delta
		if _damage_timer <= 0.0:
			_damage_timer = DAMAGE_INTERVAL
			_player.take_damage(DAMAGE, Vector2.ZERO)

	z_index = int(global_position.y / 8.0)

func _set_state(s: String) -> void:
	if _state == s:
		return
	_state = s
	match s:
		"idle":   sprite.play("idle")
		"walk":   sprite.play("walk")
		"attack": sprite.play("attack")
		"skill_windup", "skill_charge": sprite.play("skill")

func _start_skill(player_node: Node2D) -> void:
	_skill_timer = SKILL_COOLDOWN
	_charge_dir = (player_node.global_position - global_position).normalized()
	sprite.flip_h = _charge_dir.x < 0
	_set_state("skill_windup")
	var timer := get_tree().create_timer(0.55)
	await timer.timeout
	if is_dead:
		return
	_state = "skill_charge"
	_charge_timer = CHARGE_DURATION
	JuiceManager.add_trauma(0.1)

func _check_charge_hit(player_node: Node2D) -> void:
	if global_position.distance_to(player_node.global_position) < CHARGE_HIT_DIST:
		if player_node.has_method("take_damage"):
			player_node.take_damage(SKILL_DAMAGE, _charge_dir)
		_end_skill()

func _end_skill() -> void:
	_set_state("idle")
	JuiceManager.add_trauma(0.18)

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
		position += direction * 14.0
	if current_health <= 0.0:
		_die()

func receive_hit(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	take_damage(amount, direction)

func _flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2.0, 0.4, 0.4, 1.0), 0.05)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

func _die() -> void:
	is_dead = true
	_player = null
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	ProgressionManager.add_xp(xp_reward)
	JuiceManager.spawn_blood(global_position, get_parent())
	JuiceManager.apply_hitstop(0.1)
	JuiceManager.add_trauma(0.35)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func _draw() -> void:
	if is_dead or current_health >= MAX_HEALTH:
		return
	var x := -BAR_W / 2.0
	draw_rect(Rect2(x, BAR_Y, BAR_W, BAR_H), Color(0.15, 0.0, 0.0, 0.85))
	var fill := BAR_W * (current_health / MAX_HEALTH)
	draw_rect(Rect2(x, BAR_Y, fill, BAR_H), Color(0.85, 0.15, 0.15, 1.0))

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		_player = body
		_damage_timer = 0.0
		_set_state("attack")

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
		if _state == "attack":
			_set_state("idle")
