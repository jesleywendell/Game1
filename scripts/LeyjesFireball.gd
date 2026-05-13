extends Area2D

# Projétil do boss 2 (LeyjesMosca) — fireball com leve curvatura em direção ao jogador.
# Spritesheet: 2048x1792, frame 256x256, 8 cols x 7 rows, 50 frames úteis.

const SHEET      := "res://assets/enemies/lejyes_mosca/skills/sparkling_fireball_pack/sparkling-fireball-wind.png"
const FRAME_W    := 256
const FRAME_H    := 256
const SHEET_COLS := 8
const TOTAL_FRAMES := 50
const LIFETIME   := 5.5
const TURN_SPEED := 1.5   # rad/s — curvatura leve (mais fácil de desviar que Triss)

var direction := Vector2.RIGHT
var speed     := 150.0
var damage    := 22.0
var _timer    := 0.0
var _spr: AnimatedSprite2D

func _ready() -> void:
	add_to_group("lejess_projectiles")
	z_index = 5
	var tex := load(SHEET) as Texture2D
	var sf  := SpriteFrames.new()
	sf.add_animation("fly")
	sf.set_animation_speed("fly", 15.0)
	sf.set_animation_loop("fly", true)
	for i in TOTAL_FRAMES:
		var atlas    := AtlasTexture.new()
		atlas.atlas   = tex
		atlas.region  = Rect2((i % SHEET_COLS) * FRAME_W, (i / SHEET_COLS) * FRAME_H, FRAME_W, FRAME_H)
		sf.add_frame("fly", atlas)
	_spr               = AnimatedSprite2D.new()
	_spr.sprite_frames = sf
	_spr.scale         = Vector2(0.25, 0.25)
	_spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_spr.play("fly")
	add_child(_spr)
	var shape    := CircleShape2D.new()
	shape.radius  = 16.0
	var cs       := CollisionShape2D.new()
	cs.shape      = shape
	add_child(cs)
	body_entered.connect(_on_hit)

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and not player.get("is_dead"):
		var target_dir := (player.global_position - global_position).normalized()
		direction = direction.lerp(target_dir, TURN_SPEED * delta).normalized()
	position      += direction * speed * delta
	_spr.rotation  = direction.angle()
	_timer        += delta
	if _timer >= LIFETIME:
		queue_free()

func _on_hit(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, direction)
	queue_free()
