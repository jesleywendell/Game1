extends Node2D

const SHEET      := preload("res://assets/protagonista/dash/SmokeNDust P03 VFX 3.png")
const FRAME_W    := 64
const FRAME_H    := 64
const FRAME_COUNT := 7
const FPS        := 24

var _anim: AnimatedSprite2D

func _ready() -> void:
	z_index = 3
	_anim = AnimatedSprite2D.new()
	_anim.scale = Vector2(1.5, 1.5)
	_anim.sprite_frames = _build_frames()
	_anim.animation_finished.connect(queue_free)
	add_child(_anim)
	_anim.play("dash")

func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("dash")
	sf.set_animation_speed("dash", FPS)
	sf.set_animation_loop("dash", false)
	for i in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = SHEET
		atlas.region = Rect2(i * FRAME_W, 0, FRAME_W, FRAME_H)
		sf.add_frame("dash", atlas)
	return sf
