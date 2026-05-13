extends Node2D

# Orb VFX2 que orbita em volta da Triss como filho dela.
# Dano por proximidade a cada tick — força o jogador a não ficar perto.

const VFX2_SHEET    := "res://assets/enemies/triss/skills/blood_mage/VFX2/sprite-sheet.png"
const VFX2_FRAMES   := 12
const VFX2_FRAME_SZ := 128

const ORBIT_RADIUS  := 82.0
const DAMAGE_RADIUS := 44.0
const DAMAGE_TICK   := 0.35   # intervalo entre ticks de dano

var orbit_speed := 1.6   # rad/s — aumenta na fase 2
var damage      := 14.0
var _angle      := 0.0
var _dmg_tick   := 0.0

func _ready() -> void:
	z_index = 5
	var tex := load(VFX2_SHEET) as Texture2D
	var sf  := SpriteFrames.new()
	sf.add_animation("spin")
	sf.set_animation_speed("spin", 10.0)
	sf.set_animation_loop("spin", true)
	for i in VFX2_FRAMES:
		var atlas    := AtlasTexture.new()
		atlas.atlas   = tex
		atlas.region  = Rect2(i * VFX2_FRAME_SZ, 0, VFX2_FRAME_SZ, VFX2_FRAME_SZ)
		sf.add_frame("spin", atlas)
	var spr              := AnimatedSprite2D.new()
	spr.sprite_frames     = sf
	spr.scale             = Vector2(0.55, 0.55)
	spr.texture_filter    = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.play("spin")
	add_child(spr)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	_angle   += orbit_speed * delta
	position  = Vector2(ORBIT_RADIUS, 0.0).rotated(_angle)
	_dmg_tick += delta
	if _dmg_tick < DAMAGE_TICK:
		return
	_dmg_tick = 0.0
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var dist := global_position.distance_to(player.global_position)
	if dist < DAMAGE_RADIUS and player.has_method("take_damage"):
		var dir: Vector2 = (player.global_position - global_position).normalized()
		player.take_damage(damage, dir)

func set_initial_angle(a: float) -> void:
	_angle = a
	position = Vector2(ORBIT_RADIUS, 0.0).rotated(_angle)
