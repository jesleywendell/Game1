extends Area2D

# Projétil teleguiado da Triss — gira em direção ao jogador com turn_speed.
# Jogador precisa usar dash para escapar.

const SHEET     := "res://assets/enemies/triss/skills/blood_mage/VFX3/sprite-sheet.png"
const FRAMES    := 4
const FRAME_SZ  := 128
const LIFETIME  := 5.5
const TURN_SPEED := 2.8   # rad/s — velocidade de curvatura

var direction := Vector2.RIGHT
var speed     := 185.0
var damage    := 14.0
var _timer    := 0.0
var _spr: AnimatedSprite2D

func _ready() -> void:
	add_to_group("triss_projectiles")
	z_index = 6
	var tex := load(SHEET) as Texture2D
	var sf  := SpriteFrames.new()
	sf.add_animation("fly")
	sf.set_animation_speed("fly", 10.0)
	sf.set_animation_loop("fly", true)
	for i in FRAMES:
		var atlas    := AtlasTexture.new()
		atlas.atlas   = tex
		atlas.region  = Rect2(i * FRAME_SZ, 0, FRAME_SZ, FRAME_SZ)
		sf.add_frame("fly", atlas)
	_spr              = AnimatedSprite2D.new()
	_spr.sprite_frames = sf
	_spr.scale         = Vector2(0.50, 0.50)
	_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_spr.play("fly")
	add_child(_spr)
	var shape    := CircleShape2D.new()
	shape.radius  = 18.0
	var cs       := CollisionShape2D.new()
	cs.shape      = shape
	add_child(cs)
	body_entered.connect(_on_hit)

func _physics_process(delta: float) -> void:
	# Homeia em direção ao jogador com curvatura limitada
	if is_inside_tree():
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player and not player.get("is_dead"):
			var target_dir: Vector2 = (player.global_position - global_position).normalized()
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
