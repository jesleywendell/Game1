extends CharacterBody2D

@export var speed: float = 200.0
@export var dash_speed: float = 700.0
@export var dash_time: float = 0.15
@export var dash_cooldown: float = 1
@export var attack_damage: float = 1.0
@export var attack_duration: float = 0.35
@export var attack_cooldown: float = 0.2
@export var attack_hitbox_distance: float = 28.0

const FRAME_W := 64
const FRAME_H := 64
const IDLE_FRAME_COUNT := 4
const RUN_FRAME_COUNT := 8
const BITE_FRAME_COUNT := 15
const WOLF_IDLE_PATH := "res://assets/critters/critters/wolf/wolf-idle.png"
const WOLF_RUN_PATH := "res://assets/critters/critters/wolf/wolf-run.png"
const WOLF_BITE_PATH := "res://assets/critters/critters/wolf/wolf-bite.png"
const DIR_SW := "sw"
const DIR_SE := "se"
const DIR_NW := "nw"
const DIR_NE := "ne"
const DIRECTION_ROWS := {
	DIR_SW: 0,
	DIR_SE: 1,
	DIR_NW: 2,
	DIR_NE: 3,
}

var dash_direction := Vector2.ZERO
var last_move_dir := Vector2.DOWN
var last_facing := DIR_SE
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

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea2D
@onready var attack_shape: CollisionShape2D = $AttackArea2D/CollisionShape2D
@onready var skill_manager: Node = $SkillManager

func _ready() -> void:
	_setup_wolf_animations()
	_disable_attack_hitbox()

func _setup_wolf_animations() -> void:
	var frames := SpriteFrames.new()
	var idle_tex: Texture2D = load(WOLF_IDLE_PATH)
	var run_tex: Texture2D = load(WOLF_RUN_PATH)
	var bite_tex: Texture2D = load(WOLF_BITE_PATH)

	for direction in DIRECTION_ROWS.keys():
		var row: int = int(DIRECTION_ROWS[direction])
		_add_animation(frames, "idle_" + direction, idle_tex, row, IDLE_FRAME_COUNT, 6.0)
		_add_animation(frames, "run_" + direction, run_tex, row, RUN_FRAME_COUNT, 10.0)
		_add_animation(frames, "bite_" + direction, bite_tex, row, BITE_FRAME_COUNT, 20.0, false)

	sprite.sprite_frames = frames
	sprite.play("idle_" + last_facing)

func _add_animation(
	frames: SpriteFrames,
	name: String,
	texture: Texture2D,
	row: int,
	frame_count: int,
	fps: float,
	loop: bool = true
) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, fps)
	frames.set_animation_loop(name, loop)

	for i in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)
		frames.add_frame(name, atlas)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			attack_requested = true

func _physics_process(delta: float) -> void:
	var move_dir := _get_move_input()

	# Skill input — must be before is_attacking/is_dashing/else block
	# so skill_e is never suppressed by those states
	if Input.is_action_just_pressed("skill_q"):
		if not is_dashing and not is_attacking:
			skill_manager.use_q(self)
	if Input.is_action_just_pressed("skill_e"):
		skill_manager.use_e(self, get_global_mouse_position())

	if cooldown_timer > 0:
		cooldown_timer -= delta
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

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

	var target_animation := ""
	if is_attacking:
		target_animation = "bite_" + last_facing
	elif visual_dir != Vector2.ZERO:
		last_facing = _resolve_facing(visual_dir)
		target_animation = "run_" + last_facing
	else:
		target_animation = "idle_" + last_facing

	if sprite.animation != target_animation or not sprite.is_playing():
		sprite.play(target_animation)

	sprite.flip_h = false

func start_dash(direction: Vector2) -> void:
	if is_attacking:
		return
	is_dashing = true
	dash_timer = dash_time
	cooldown_timer = dash_cooldown
	dash_direction = direction.normalized()

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

	var x := signf(direction.x)
	var y := signf(direction.y)

	if y < 0.0:
		if x > 0.0:
			return DIR_NE
		return DIR_NW

	if y > 0.0:
		if x < 0.0:
			return DIR_SW
		return DIR_SE

	if x < 0.0:
		return DIR_SW
	if x > 0.0:
		return DIR_NE

	return last_facing

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
	if skill_manager and skill_manager.skill_q_active_timer > 0.0:
		draw_arc(Vector2.ZERO, 80.0, 0.0, TAU, 32, Color(0.6, 0.0, 1.0, 0.8), 2.0)

func _damage_target(target: Node) -> void:
	if hit_targets.has(target):
		return

	hit_targets.append(target)

	if target.has_method("take_damage"):
		target.call("take_damage", attack_damage, attack_direction)
	elif target.has_method("receive_hit"):
		target.call("receive_hit", attack_damage, attack_direction)
