extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var game_over_label: Label = $GameOverLabel

const _HP_CROP := Rect2i(138, 338, 1310, 293)
const _HP_FILL_SRC := Rect2i(333, 445, 867, 82)

const _XP_CROP := Rect2i(94, 343, 1375, 243)
const _XP_FILL_SRC := Rect2i(290, 445, 970, 107)

const HP_FRAME := "res://assets/life/bar_frame.png"
const HP_FILL := "res://assets/life/bar_fill.png"

const XP_FRAME := "res://assets/xp/xp_background.png"
const XP_FILL := "res://assets/xp/xp_bar_fill.png"

const HP_FILL_OFFSET_X := 46.43
const HP_FILL_OFFSET_Y := 0
const HP_FILL_SIZE_OFFSET_X := -18
const HP_FILL_SIZE_OFFSET_Y := 0

const XP_INNER_LEFT := 66
const XP_INNER_RIGHT := 40
const XP_INNER_TOP := 27
const XP_INNER_BOTTOM := 24

var _tween: Tween
var _wave_label: Label
var _level_label: Label
var _xp_bar: TextureProgressBar

func _ready() -> void:
	var vp := get_viewport().get_visible_rect().size

	var mg := int(vp.x * 0.01)
	var bw := int(vp.x * 0.22)

	var bh := int(round(float(bw) / 4.473))
	var xh := int(round(float(bw) / 5.658))

	var hp_bg := TextureRect.new()
	hp_bg.texture = _load_cropped(HP_FRAME, _HP_CROP, bw, bh)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bg.set_position(Vector2(mg, mg))
	hp_bg.set_size(Vector2(bw, bh))
	hp_bg.z_index = 1
	add_child(hp_bg)

	var hp_slot := _slot_from_source(_HP_CROP, _HP_FILL_SRC, bw, bh)
	hp_slot.position.x += HP_FILL_OFFSET_X
	hp_slot.position.y += HP_FILL_OFFSET_Y
	hp_slot.size.x += HP_FILL_SIZE_OFFSET_X
	hp_slot.size.y += HP_FILL_SIZE_OFFSET_Y

	health_bar.min_value = 0.0
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	health_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	health_bar.texture_under = null
	health_bar.texture_over = null
	health_bar.texture_progress = _load_cropped(
		HP_FILL,
		_HP_FILL_SRC,
		hp_slot.size.x,
		hp_slot.size.y
	)
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.set_position(Vector2(mg + hp_slot.position.x, mg + hp_slot.position.y))
	health_bar.set_size(Vector2(hp_slot.size.x, hp_slot.size.y))
	health_bar.z_index = 2

	var xp_y := mg + bh + 3

	var xp_bg := TextureRect.new()
	xp_bg.texture = _load_cropped(XP_FRAME, _XP_CROP, bw, xh)
	xp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_bg.set_position(Vector2(mg, xp_y))
	xp_bg.set_size(Vector2(bw, xh))
	xp_bg.z_index = 1
	add_child(xp_bg)

	var xp_fill_x := XP_INNER_LEFT
	var xp_fill_y := XP_INNER_TOP
	var xp_fill_w := bw - XP_INNER_LEFT - XP_INNER_RIGHT
	var xp_fill_h := xh - XP_INNER_TOP - XP_INNER_BOTTOM

	_xp_bar = TextureProgressBar.new()
	_xp_bar.min_value = 0.0
	_xp_bar.max_value = 100.0
	_xp_bar.value = 0.0
	_xp_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	_xp_bar.texture_under = null
	_xp_bar.texture_over = null
	_xp_bar.texture_progress = _load_cropped(
		XP_FILL,
		_XP_FILL_SRC,
		xp_fill_w,
		xp_fill_h
	)
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_bar.set_position(Vector2(mg + xp_fill_x, xp_y + xp_fill_y))
	_xp_bar.set_size(Vector2(xp_fill_w, xp_fill_h))
	_xp_bar.z_index = 2
	add_child(_xp_bar)

	var font_sz := int(vp.y * 0.022)

	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", font_sz)
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level_label.modulate = Color(0.78, 0.55, 1.0)
	_level_label.set_position(Vector2(mg + bw + 8, xp_y))
	_level_label.set_size(Vector2(120, xh))
	_level_label.z_index = 3
	add_child(_level_label)

	_wave_label = Label.new()
	_wave_label.text = "Wave 1"
	_wave_label.add_theme_font_size_override("font_size", int(vp.y * 0.018))
	_wave_label.modulate = Color(0.85, 1.0, 0.85, 0.9)
	_wave_label.set_position(Vector2(mg, xp_y + xh + int(vp.y * 0.007)))
	_wave_label.z_index = 3
	add_child(_wave_label)

	ProgressionManager.xp_changed.connect(on_xp_changed)

	on_xp_changed(
		ProgressionManager.data.current_xp,
		ProgressionManager.xp_required(ProgressionManager.data.level)
	)

func _slot_from_source(frame_crop: Rect2i, fill_src: Rect2i, out_w: int, out_h: int) -> Rect2i:
	var rel_x := fill_src.position.x - frame_crop.position.x
	var rel_y := fill_src.position.y - frame_crop.position.y

	var slot_x := int(round(float(rel_x) / float(frame_crop.size.x) * float(out_w)))
	var slot_y := int(round(float(rel_y) / float(frame_crop.size.y) * float(out_h)))
	var slot_w := int(round(float(fill_src.size.x) / float(frame_crop.size.x) * float(out_w)))
	var slot_h := int(round(float(fill_src.size.y) / float(frame_crop.size.y) * float(out_h)))

	return Rect2i(
		slot_x,
		slot_y,
		max(1, slot_w),
		max(1, slot_h)
	)

func _load_cropped(path: String, crop: Rect2i, out_w: int, out_h: int) -> ImageTexture:
	var img := Image.load_from_file(path)
	var region := img.get_region(crop)

	region.resize(
		max(1, out_w),
		max(1, out_h),
		Image.INTERPOLATE_LANCZOS
	)

	return ImageTexture.create_from_image(region)

func on_health_changed(current: float, maximum: float) -> void:
	if maximum <= 0.0:
		return

	var target := clampf(current / maximum * 100.0, 0.0, 100.0)

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(health_bar, "value", target, 0.3).set_ease(Tween.EASE_OUT)

func on_xp_changed(current: float, required: float) -> void:
	if required <= 0.0:
		return

	var target := clampf(current / required * 100.0, 0.0, 100.0)

	var tween := create_tween()
	tween.tween_property(_xp_bar, "value", target, 0.3).set_ease(Tween.EASE_OUT)

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
