extends CharacterBody2D

@export var speed: float = 200.0
@export var dash_speed: float = 700.0
@export var dash_time: float = 0.15
@export var dash_cooldown: float = 1

var dash_direction := Vector2.ZERO
var last_move_dir := Vector2.DOWN
var is_dashing := false
var dash_timer := 0.0
var cooldown_timer := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Wolf sprite sheet layout: 64x64 frames, 4 cols x 4 rows
# Row 0 = SE direction (facing down-right)
const FRAME_W := 64
const FRAME_H := 64

func _ready() -> void:
	_setup_wolf_animations()

func _setup_wolf_animations() -> void:
	var frames := SpriteFrames.new()

	# Idle: wolf-idle.png (256x256) -> 4 cols x 4 rows at 64x64
	var idle_tex: Texture2D = load("res://assets/critters/critters/wolf/wolf-idle.png")

	# Row 3 = S/SW direction (facing toward camera). Adjust (0, 1, 2) if still wrong.
	var idle_row := 0 * FRAME_H

	frames.add_animation("idle")
	frames.set_animation_speed("idle", 6.0)
	frames.set_animation_loop("idle", true)

	for i in 4:
		var atlas := AtlasTexture.new()
		atlas.atlas = idle_tex
		atlas.region = Rect2(i * FRAME_W, idle_row, FRAME_W, FRAME_H)
		frames.add_frame("idle", atlas)

	# Run: wolf-run.png (512x256) -> 8 cols x 4 rows at 64x64
	var run_tex: Texture2D = load("res://assets/critters/critters/wolf/wolf-run.png")
	var run_row := 0 * FRAME_H

	frames.add_animation("run")
	frames.set_animation_speed("run", 10.0)
	frames.set_animation_loop("run", true)

	for i in 8:
		var atlas := AtlasTexture.new()
		atlas.atlas = run_tex
		atlas.region = Rect2(i * FRAME_W, run_row, FRAME_W, FRAME_H)
		frames.add_frame("run", atlas)

	sprite.sprite_frames = frames
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	var move_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if cooldown_timer > 0:
		cooldown_timer -= delta

	if is_dashing:
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

func _update_animation(move_dir: Vector2) -> void:
	if move_dir != Vector2.ZERO or is_dashing:
		sprite.play("run")

		if move_dir.x < 0:
			sprite.flip_h = false # natural direction faces left
		elif move_dir.x > 0:
			sprite.flip_h = true # flipped to face right
	else:
		sprite.play("idle")

func start_dash(direction: Vector2) -> void:
	is_dashing = true
	dash_timer = dash_time
	cooldown_timer = dash_cooldown
	dash_direction = direction.normalized()
