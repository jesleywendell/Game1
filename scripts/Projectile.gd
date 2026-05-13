extends Area2D

const SPEED    := 400.0
const LIFETIME := 2.0
const SHEET    := "res://assets/protagonista/walk_2/spritesheet_personagem1.png"
const FRAME_W  := 64
const FRAME_H  := 64
# Row 7 (y=448), col 0 (x=0): orb projectile sprite
const ORB_ROW := 7
const ORB_COL := 0

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
	frames.set_animation_speed("fly", 8.0)
	frames.set_animation_loop("fly", true)
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(ORB_COL * FRAME_W, ORB_ROW * FRAME_H, FRAME_W, FRAME_H)
	frames.add_frame("fly", atlas)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = Vector2(0.5, 0.5)
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
