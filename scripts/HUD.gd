extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var game_over_label: Label         = $GameOverLabel

const BAR_W        := 240
const BAR_H        := 160
const MARGIN       := 12.0
const FILL_OFFSET_X := 19.5  # desloca o fill para a direita (ajuste fino aqui)

var _tween: Tween

func _ready() -> void:
	health_bar.texture_under    = _load_resized("res://assets/life/bar_frame.png", 0)
	health_bar.texture_progress = _load_resized("res://assets/life/bar_fill.png", FILL_OFFSET_X)
	health_bar.custom_minimum_size = Vector2.ZERO
	health_bar.set_position(Vector2(MARGIN, MARGIN))
	health_bar.set_size(Vector2(BAR_W, BAR_H))

func _load_resized(path: String, x_offset: int) -> ImageTexture:
	var img := Image.load_from_file(path)
	img.resize(BAR_W, BAR_H, Image.INTERPOLATE_LANCZOS)
	if x_offset <= 0:
		return ImageTexture.create_from_image(img)
	var canvas := Image.create(BAR_W, BAR_H, true, Image.FORMAT_RGBA8)
	canvas.blit_rect(img, Rect2i(0, 0, BAR_W - x_offset, BAR_H), Vector2i(x_offset, 0))
	return ImageTexture.create_from_image(canvas)

func on_health_changed(current: float, maximum: float) -> void:
	var target := (current / maximum) * 100.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(health_bar, "value", target, 0.3).set_ease(Tween.EASE_OUT)

func on_player_died() -> void:
	game_over_label.visible = true
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
