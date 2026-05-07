extends Node2D

const SHEET_START := preload("res://assets/protagonista/skills/blood_mage/VFX1/part1(start)/sprite-sheet.png")
const SHEET_LOOP  := preload("res://assets/protagonista/skills/blood_mage/VFX1/part2(loop)/sprite-sheet.png")
const SHEET_END   := preload("res://assets/protagonista/skills/blood_mage/VFX1/part3(end)/sprite-sheet.png")

const FRAME_SIZE   := Vector2i(128, 128)
const FPS          := 12
const VFX_SCALE    := 1.0
const SPIN_SPEED   := 3.0   # rad/s
const ORBIT_RADIUS := 55.0  # pixels do centro do player

var _anim: AnimatedSprite2D
var _spinning := true

func _ready() -> void:
	z_index = 5
	_anim = AnimatedSprite2D.new()
	_anim.scale    = Vector2(VFX_SCALE, VFX_SCALE)
	_anim.position = Vector2(ORBIT_RADIUS, 0.0)
	_anim.sprite_frames = _build_frames()
	_anim.animation_finished.connect(_on_anim_finished)
	add_child(_anim)
	_anim.play("start")

func _process(delta: float) -> void:
	if _spinning:
		rotation += SPIN_SPEED * delta

func finish() -> void:
	_spinning = false
	_anim.play("end")

func _on_anim_finished() -> void:
	match _anim.animation:
		"start": _anim.play("loop")
		"end":   queue_free()

func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	_add_strip(sf, "start", SHEET_START, 8, false)
	_add_strip(sf, "loop",  SHEET_LOOP,  5, true)
	_add_strip(sf, "end",   SHEET_END,   6, false)
	return sf

func _add_strip(sf: SpriteFrames, anim_name: String, sheet: Texture2D, count: int, looping: bool) -> void:
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, FPS)
	sf.set_animation_loop(anim_name, looping)
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
		sf.add_frame(anim_name, atlas)
