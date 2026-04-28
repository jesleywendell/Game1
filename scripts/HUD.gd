extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var game_over_label: Label         = $GameOverLabel

# Content bounding boxes (measured pixel-exact from 1536×1024 sources)
const _HP_CROP     := Rect2i(138, 338, 1310, 293)  # bar_frame full content
const _HP_FILL_SRC := Rect2i(333, 445,  867,  82)  # bar_fill content only
const _XP_CROP     := Rect2i( 94, 343, 1375, 243)  # xp_background full content
const _XP_FILL_SRC := Rect2i(290, 445,  970, 107)  # xp_bar_fill trimmed to slot

const XP_FRAME := "res://assets/xp/xp_background.png"
const XP_FILL  := "res://assets/xp/xp_bar_fill.png"

var _tween: Tween
var _wave_label: Label
var _level_label: Label
var _xp_bar: TextureProgressBar

func _ready() -> void:
	var vp  := get_viewport().get_visible_rect().size
	var mg  := int(vp.x * 0.01)
	var bw  := int(vp.x * 0.22)
	var bh  := int(bw / 4.473)   # natural ratio of bar_frame (1310÷293)
	var xh  := int(bw / 5.658)   # natural ratio of xp_background (1375÷243)

	# ── Health bar ──────────────────────────────────────────────────────────
	# Background: full frame (heart ornament always visible)
	var hp_bg := TextureRect.new()
	hp_bg.texture      = _load_cropped("res://assets/life/bar_frame.png", _HP_CROP, bw, bh)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bg.set_position(Vector2(mg, mg))
	hp_bg.set_size(Vector2(bw, bh))
	add_child(hp_bg)
	move_child(hp_bg, 0)  # draw below health_bar fill

	# Fill: positioned exactly over the dark slot (after heart, before arrow tip)
	var hfx := int(bw * 0.149)                    # ~63px — right edge of heart
	var hfy := int(bh * 0.365)                    # ~34px — vertical slot centre
	var hfw := bw - hfx - int(bw * 0.068)         # ~331px — leaves arrow-tip area
	var hfh := int(bh * 0.280)                    # ~26px — slot height
	health_bar.texture_under    = null
	health_bar.texture_progress = _load_cropped("res://assets/life/bar_fill.png", _HP_FILL_SRC, hfw, hfh)
	health_bar.custom_minimum_size = Vector2.ZERO
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.set_position(Vector2(mg + hfx, mg + hfy))
	health_bar.set_size(Vector2(hfw, hfh))

	# ── XP bar ───────────────────────────────────────────────────────────────
	var xp_y := mg + bh + 3

	# Background: full xp_background frame (diamonds always visible)
	var xp_bg := TextureRect.new()
	xp_bg.texture      = _load_cropped(XP_FRAME, _XP_CROP, bw, xh)
	xp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_bg.set_position(Vector2(mg, xp_y))
	xp_bg.set_size(Vector2(bw, xh))
	add_child(xp_bg)

	# Fill: positioned between the diamond ornaments (x=14.3%–85.5% of bw)
	var xfx := int(bw * 0.143)                    # ~60px — inner edge of left diamond
	var xfy := int(xh * 0.420)                    # ~31px — vertical slot centre
	var xfw := bw - xfx - int(bw * 0.145)         # ~298px — inner edge of right diamond
	var xfh := int(xh * 0.440)                    # ~32px — slot height
	_xp_bar = TextureProgressBar.new()
	_xp_bar.min_value    = 0.0
	_xp_bar.max_value    = 100.0
	_xp_bar.value        = 0.0
	_xp_bar.fill_mode    = 0
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_bar.texture_progress = _load_cropped(XP_FILL, _XP_FILL_SRC, xfw, xfh)
	_xp_bar.set_position(Vector2(mg + xfx, xp_y + xfy))
	_xp_bar.set_size(Vector2(xfw, xfh))
	add_child(_xp_bar)

	# Level label — right of XP bar, vertically centred
	var font_sz := int(vp.y * 0.022)
	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", font_sz)
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level_label.modulate = Color(0.78, 0.55, 1.0)
	_level_label.set_position(Vector2(mg + bw + 8, xp_y))
	_level_label.set_size(Vector2(120, xh))
	add_child(_level_label)

	# Wave label — below XP bar
	_wave_label = Label.new()
	_wave_label.text = "Wave 1"
	_wave_label.add_theme_font_size_override("font_size", int(vp.y * 0.018))
	_wave_label.modulate = Color(0.85, 1.0, 0.85, 0.9)
	_wave_label.set_position(Vector2(mg, xp_y + xh + int(vp.y * 0.007)))
	add_child(_wave_label)

	ProgressionManager.xp_changed.connect(on_xp_changed)
	on_xp_changed(ProgressionManager.data.current_xp,
		ProgressionManager.xp_required(ProgressionManager.data.level))

func _load_cropped(path: String, crop: Rect2i, out_w: int, out_h: int) -> ImageTexture:
	var img    := Image.load_from_file(path)
	var region := img.get_region(crop)
	region.resize(out_w, out_h, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(region)

func on_health_changed(current: float, maximum: float) -> void:
	var target := current / maximum * 100.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(health_bar, "value", target, 0.3).set_ease(Tween.EASE_OUT)

func on_xp_changed(current: float, required: float) -> void:
	var tween := create_tween()
	tween.tween_property(_xp_bar, "value", clampf(current / required * 100.0, 0.0, 100.0), 0.3).set_ease(Tween.EASE_OUT)
	_level_label.text = "Lv.%d" % ProgressionManager.data.level

func on_wave_started(wave_number: int) -> void:
	_wave_label.text = "Wave %d" % wave_number
	var tween := create_tween()
	tween.tween_property(_wave_label, "modulate:a", 1.0, 0.0)
	tween.tween_property(_wave_label, "modulate:a", 0.9, 0.4)

func on_player_died() -> void:
	game_over_label.visible = true
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
