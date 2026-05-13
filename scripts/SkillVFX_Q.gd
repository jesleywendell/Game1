extends Node2D

const PLAYER_SHEET := "res://assets/protagonista/walk_2/spritesheet_personagem1.png"
const FRAME_W      := 64
const FRAME_H      := 64
const SLASH_ROW    := 6
const SLASH_FRAMES := 7
const SLASH_FPS    := 14.0
const SPIN_SPEED   := 3.5   # rad/s
const ORBIT_RADIUS := 55.0

var _spinning := true

func _ready() -> void:
	z_index = 5
	var tex: Texture2D = load(PLAYER_SHEET)
	var sf := _build_frames(tex)
	for i in 2:
		var arc := AnimatedSprite2D.new()
		arc.sprite_frames = sf
		arc.centered = true
		arc.scale = Vector2(1.6, 1.6)
		arc.position = Vector2(ORBIT_RADIUS, 0.0).rotated(i * PI)
		arc.play("slash")
		add_child(arc)

func _process(delta: float) -> void:
	if _spinning:
		rotation += SPIN_SPEED * delta

func finish() -> void:
	_spinning = false
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)

func _build_frames(tex: Texture2D) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("slash")
	sf.set_animation_speed("slash", SLASH_FPS)
	sf.set_animation_loop("slash", true)
	for i in SLASH_FRAMES:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * FRAME_W, SLASH_ROW * FRAME_H, FRAME_W, FRAME_H)
		sf.add_frame("slash", atlas)
	return sf
