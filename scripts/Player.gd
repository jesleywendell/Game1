extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal died

@export var speed: float = 200.0
@export var dash_speed: float = 700.0
@export var dash_time: float = 0.15
@export var dash_cooldown: float = 1.0
@export var attack_damage: float = 15.0
@export var attack_duration: float = 0.35
@export var attack_cooldown: float = 0.2
@export var attack_hitbox_distance: float = 42.0
@export var max_health: float = 100.0

const FRAME_W := 175
const FRAME_H := 131
const WALK_COLS := 4
const WALK_FPS  := 8.0
const AZRAEL_PATH := "res://assets/protagonista/walk/azrael_walk.png"
# Ordem das linhas na sheet: DOWN, DOWN-LEFT, LEFT, UP-LEFT, UP, UP-RIGHT, RIGHT, DOWN-RIGHT
const WALK_ROW_ORDER: Array[String] = ["S","SW","W","NW","N","NE","E","SE"]
const INVINCIBILITY_DURATION := 0.6
const KNOCKBACK_FORCE := 120.0
const REGEN_DELAY  := 10.0
const REGEN_AMOUNT := 10.0
const REGEN_TICK   := 1.0

var current_health: float
var is_dead := false
var _base_speed: float
var _base_attack_damage: float
var _base_max_health: float
var dash_direction := Vector2.ZERO
var last_move_dir := Vector2.DOWN
var last_facing := "SE"
var is_dashing := false
var is_attacking := false
var attack_direction := Vector2.ZERO
var dash_timer := 0.0
var cooldown_timer := 0.0
var attack_timer := 0.0
var attack_cooldown_timer := 0.0
var attack_hit_active := false
var hit_targets: Array[Node] = []
var attack_requested := false
var _invincibility_timer := 0.0
var _base_dash_cooldown := 0.0
var _temp_damage_bonus  := 0.0
var _temp_hp_bonus      := 0.0
var _temp_speed_bonus   := 0.0
var _temp_dash_cd_bonus  := 0.0
var _no_damage_timer     := 0.0
var _regen_tick_timer    := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea2D
@onready var attack_shape: CollisionShape2D = $AttackArea2D/CollisionShape2D
@onready var skill_manager: Node = $SkillManager
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	_base_speed = speed
	_base_attack_damage = attack_damage
	_base_max_health = max_health
	_base_dash_cooldown = dash_cooldown
	_apply_stats()
	_setup_azrael_animations()
	_disable_attack_hitbox()
	(attack_shape.shape as RectangleShape2D).size = Vector2(56, 40)
	health_changed.emit(current_health, max_health)
	camera.zoom = Vector2(2.0, 2.0)
	ProgressionManager.upgrade_applied.connect(_apply_stats)

func _apply_stats() -> void:
	speed = ProgressionManager.get_speed(_base_speed) + _temp_speed_bonus
	attack_damage = ProgressionManager.get_attack_damage(_base_attack_damage) + _temp_damage_bonus
	dash_cooldown = maxf(0.3, _base_dash_cooldown - _temp_dash_cd_bonus)
	var new_max := ProgressionManager.get_max_health(_base_max_health) + _temp_hp_bonus
	if current_health == 0.0:
		current_health = new_max
	elif new_max > max_health:
		current_health = minf(current_health + (new_max - max_health), new_max)
	else:
		current_health = minf(current_health, new_max)
	max_health = new_max
	health_changed.emit(current_health, max_health)

func _setup_azrael_animations() -> void:
	var frames := SpriteFrames.new()
	var tex: Texture2D = load(AZRAEL_PATH)
	for row_idx in WALK_ROW_ORDER.size():
		var anim := "walk_" + WALK_ROW_ORDER[row_idx]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, WALK_FPS)
		frames.set_animation_loop(anim, true)
		for col in WALK_COLS:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * FRAME_W, row_idx * FRAME_H, FRAME_W, FRAME_H)
			frames.add_frame(anim, atlas)
	sprite.sprite_frames = frames
	sprite.centered = false
	sprite.scale = Vector2(0.5, 0.5)
	sprite.offset = Vector2(-FRAME_W / 2.0, -FRAME_H)
	sprite.play("walk_" + last_facing)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if not get_tree().paused and not is_dead:
				attack_requested = true

func _physics_process(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		sprite.modulate.a = 0.4 if (int(_invincibility_timer * 10) % 2 == 1) else 1.0
		if _invincibility_timer <= 0.0:
			sprite.modulate.a = 1.0
	var move_dir := _get_move_input()

	if Input.is_action_just_pressed("skill_q"):
		if not is_dashing and not is_attacking:
			skill_manager.use_q(self)
	if Input.is_action_just_pressed("skill_e"):
		skill_manager.use_e(self, get_global_mouse_position())

	if cooldown_timer > 0:
		cooldown_timer -= delta
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	if not is_dead and current_health < max_health:
		_no_damage_timer += delta
		if _no_damage_timer >= REGEN_DELAY:
			_regen_tick_timer -= delta
			if _regen_tick_timer <= 0.0:
				_regen_tick_timer = REGEN_TICK
				current_health = minf(current_health + REGEN_AMOUNT, max_health)
				health_changed.emit(current_health, max_health)

	if attack_requested and _can_start_attack():
		_start_attack()
	attack_requested = false

	if is_attacking:
		_update_attack(delta)
		velocity = Vector2.ZERO
	elif is_dashing:
		dash_timer -= delta
		velocity = dash_direction * dash_speed
		if dash_timer <= 0:
			is_dashing = false
	else:
		velocity = move_dir * speed
		if move_dir != Vector2.ZERO:
			last_move_dir = move_dir
		if Input.is_action_just_pressed("dash") and cooldown_timer <= 0:
			start_dash(last_move_dir)

	move_and_slide()
	_update_animation(move_dir)
	queue_redraw()

func _update_animation(move_dir: Vector2) -> void:
	var visual_dir := move_dir
	if visual_dir == Vector2.ZERO and is_dashing:
		visual_dir = dash_direction

	if visual_dir != Vector2.ZERO:
		last_facing = _resolve_facing(visual_dir)

	var anim := "walk_" + last_facing
	if visual_dir == Vector2.ZERO and not is_dashing:
		if sprite.is_playing() or sprite.animation != anim:
			sprite.animation = anim
			sprite.stop()
			sprite.frame = 0
	else:
		if sprite.animation != anim or not sprite.is_playing():
			sprite.play(anim)
	sprite.flip_h = false

func start_dash(direction: Vector2) -> void:
	if is_attacking:
		return
	is_dashing = true
	dash_timer = dash_time
	cooldown_timer = dash_cooldown
	dash_direction = direction.normalized()
	AudioManager.play_sfx("dash")

func _get_move_input() -> Vector2:
	var x := Input.get_axis("move_left", "move_right")
	var y := Input.get_axis("move_up", "move_down")
	var input_dir := Vector2(x, y)
	if input_dir.length_squared() > 1.0:
		input_dir = input_dir.normalized()
	return input_dir

func _resolve_facing(direction: Vector2) -> String:
	if direction == Vector2.ZERO:
		return last_facing
	var deg := fmod(rad_to_deg(direction.angle()) + 360.0, 360.0)
	# 0=E,45=SE,90=S,135=SW,180=W,225=NW,270=N,315=NE
	const DIRS: Array[String] = ["E","SE","S","SW","W","NW","N","NE"]
	return DIRS[int((deg + 22.5) / 45.0) % 8]

func _can_start_attack() -> bool:
	return not is_attacking and not is_dashing and attack_cooldown_timer <= 0.0

func _start_attack() -> void:
	is_attacking = true
	attack_timer = attack_duration
	attack_cooldown_timer = attack_cooldown
	attack_direction = (get_global_mouse_position() - global_position).normalized()
	if attack_direction == Vector2.ZERO:
		attack_direction = last_move_dir.normalized()
	if attack_direction == Vector2.ZERO:
		attack_direction = Vector2(1, 0)
	last_facing = _resolve_facing(attack_direction)
	hit_targets.clear()
	AudioManager.play_sfx("attack")
	_enable_attack_hitbox(attack_direction)

func _update_attack(delta: float) -> void:
	attack_timer -= delta
	if attack_hit_active:
		_apply_attack_damage()
	if attack_timer <= attack_duration * 0.45 and attack_hit_active:
		_disable_attack_hitbox()
	if attack_timer <= 0.0:
		is_attacking = false
		_disable_attack_hitbox()

func _enable_attack_hitbox(direction: Vector2) -> void:
	attack_area.position = direction.normalized() * attack_hitbox_distance
	attack_shape.disabled = false
	attack_hit_active = true

func _disable_attack_hitbox() -> void:
	attack_shape.disabled = true
	attack_hit_active = false

func _apply_attack_damage() -> void:
	for body in attack_area.get_overlapping_bodies():
		_damage_target(body)
	for area in attack_area.get_overlapping_areas():
		if area == attack_area:
			continue
		_damage_target(area)

func _draw() -> void:
	if is_attacking and attack_timer > 0.0:
		var progress := 1.0 - (attack_timer / attack_duration)
		var alpha    := 1.0 - progress
		var base_angle := attack_direction.angle()
		var half_arc   := deg_to_rad(55.0)
		draw_arc(Vector2.ZERO, attack_hitbox_distance + 8.0,
			base_angle - half_arc, base_angle + half_arc,
			20, Color(1.0, 0.85, 0.3, alpha * 0.9), 3.0)
	if skill_manager and skill_manager.skill_q_active_timer > 0.0:
		draw_arc(Vector2.ZERO, 80.0, 0.0, TAU, 32, Color(0.6, 0.0, 1.0, 0.8), 2.0)

func take_damage(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	if is_dead or _invincibility_timer > 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	_invincibility_timer = INVINCIBILITY_DURATION
	_no_damage_timer = 0.0
	_regen_tick_timer = REGEN_TICK
	health_changed.emit(current_health, max_health)
	_flash_hit()
	AudioManager.play_sfx("damage_player")
	JuiceManager.add_trauma(0.45)
	JuiceManager.spawn_damage_number(amount, global_position, get_parent(), true)
	if direction != Vector2.ZERO:
		velocity += direction.normalized() * KNOCKBACK_FORCE
	if current_health <= 0.0:
		_die()

func apply_temp_upgrade(type: String) -> void:
	match type:
		"damage":  _temp_damage_bonus  += attack_damage * 0.10
		"health":  _temp_hp_bonus      += 15.0
		"speed":   _temp_speed_bonus   += speed * 0.10
		"dash_cd": _temp_dash_cd_bonus += 0.2
	_apply_stats()

func drain_hp(amount: float) -> void:
	current_health = maxf(current_health - amount, 1.0)
	_no_damage_timer = 0.0
	_regen_tick_timer = REGEN_TICK
	health_changed.emit(current_health, max_health)

func _flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(2.0, 0.3, 0.3, 1.0), 0.05)
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)

func _die() -> void:
	is_dead = true
	AudioManager.play_sfx("player_die")
	set_physics_process(false)
	died.emit()
	sprite.modulate.a = 1.0

func _damage_target(target: Node) -> void:
	if target == self or hit_targets.has(target):
		return
	hit_targets.append(target)
	if target.has_method("take_damage"):
		target.call("take_damage", attack_damage, attack_direction)
	elif target.has_method("receive_hit"):
		target.call("receive_hit", attack_damage, attack_direction)
