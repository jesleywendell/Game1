extends Area2D

const SPEED   := 400.0
const LIFETIME := 2.0
const SHEET   := "res://assets/protagonista/skills/fire_bullet/All_Fire_Bullet_Pixel_16x16.png"
const FRAME_W := 16
const FRAME_H := 16
# Row 1 (y=16), cols 0-4: pulsing fire orb, 5 frames
const ANIM_ROW  := 1
const ANIM_COLS := 5

var direction := Vector2.RIGHT
var damage    := 1.5
var source: Node = null
var _lifetime_timer := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_setup_sprite()

func _setup_sprite() -> void:
	var tex: Texture2D = load(SHEET)
	var frames := SpriteFrames.new()
	frames.add_animation("fly")
	frames.set_animation_speed("fly", 10.0)
	frames.set_animation_loop("fly", true)
	for col in ANIM_COLS:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(col * FRAME_W, ANIM_ROW * FRAME_H, FRAME_W, FRAME_H)
		frames.add_frame("fly", atlas)

	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = Vector2(1.5, 1.5)
	sprite.play("fly")
	add_child(sprite)

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	_lifetime_timer += delta
	if _lifetime_timer >= LIFETIME:
		queue_free()

func _on_body_entered(body: Node) -> void:
	_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_hit(area)

func _hit(target: Node) -> void:
	if target == source:
		return
	if target.has_method("take_damage"):
		target.take_damage(damage, direction)
	elif target.has_method("receive_hit"):
		target.receive_hit(damage, direction)
	queue_free()
