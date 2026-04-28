extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var game_over_label: Label         = $GameOverLabel

const FILL_OFFSET_RATIO := 0.089
const XP_FRAME := "res://assets/xp/ChatGPT Image 27 de abr. de 2026, 17_21_53.png"
const XP_FILL  := "res://assets/xp/ChatGPT Image 27 de abr. de 2026, 17_21_40.png"
const XP_EMPTY := "res://assets/xp/ChatGPT Image 27 de abr. de 2026, 17_21_47.png"

var _tween: Tween
var _wave_label: Label
var _level_label: Label
var _xp_bar: TextureProgressBar

func _ready() -> void:
	var vp  := get_viewport().get_visible_rect().size
	var mg  := vp.x * 0.01          # ~19px @ 1080p
	var bw  := int(vp.x * 0.22)     # 422px — largura compartilhada
	var bh  := int(vp.y * 0.07)     # 76px  — barra de vida
	var xh  := int(vp.y * 0.028)    # 30px  — barra de XP (accent)
	var gap := int(vp.y * 0.004)    # 4px   — gap fixo entre barras

	# Barra de vida
	var off := int(bw * FILL_OFFSET_RATIO)
	health_bar.texture_under    = _load_img("res://assets/life/bar_frame.png", 0, bw, bh)
	health_bar.texture_progress = _load_img("res://assets/life/bar_fill.png", off, bw, bh)
	health_bar.custom_minimum_size = Vector2.ZERO
	health_bar.set_position(Vector2(mg, mg))
	health_bar.set_size(Vector2(bw, bh))

	# Barra de XP — imediatamente abaixo com gap fixo
	var xp_y := mg + bh + gap
	_xp_bar = TextureProgressBar.new()
	_xp_bar.min_value = 0.0
	_xp_bar.max_value = 100.0
	_xp_bar.value     = 0.0
	_xp_bar.fill_mode = 0
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_bar.set_position(Vector2(mg, xp_y))
	_xp_bar.set_size(Vector2(bw, xh))
	_xp_bar.texture_under    = _load_img(XP_EMPTY, 0, bw, xh)
	_xp_bar.texture_progress = _load_img(XP_FILL,  0, bw, xh)
	_xp_bar.texture_over     = _load_img(XP_FRAME, 0, bw, xh)
	add_child(_xp_bar)

	# Lv.N — alinhado verticalmente ao centro da barra de XP
	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", int(vp.y * 0.016))
	_level_label.modulate = Color(0.78, 0.55, 1.0)
	_level_label.set_position(Vector2(mg + bw + 6.0, xp_y + (xh - int(vp.y * 0.016)) * 0.5))
	add_child(_level_label)

	# Wave label — 8px abaixo do XP bar
	_wave_label = Label.new()
	_wave_label.text = "Wave 1"
	_wave_label.add_theme_font_size_override("font_size", int(vp.y * 0.018))
	_wave_label.modulate = Color(0.85, 1.0, 0.85, 0.9)
	_wave_label.set_position(Vector2(mg, xp_y + xh + int(vp.y * 0.007)))
	add_child(_wave_label)

	ProgressionManager.xp_changed.connect(on_xp_changed)
	on_xp_changed(ProgressionManager.data.current_xp,
		ProgressionManager.xp_required(ProgressionManager.data.level))

func _load_img(path: String, x_off: int, w: int, h: int) -> ImageTexture:
	var img := Image.load_from_file(path)
	img.resize(w, h, Image.INTERPOLATE_LANCZOS)
	if x_off <= 0:
		return ImageTexture.create_from_image(img)
	var canvas := Image.create(w, h, true, Image.FORMAT_RGBA8)
	canvas.blit_rect(img, Rect2i(0, 0, w - x_off, h), Vector2i(x_off, 0))
	return ImageTexture.create_from_image(canvas)

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
