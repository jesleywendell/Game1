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
var _heart_labels: Array[Label] = []
var _q_bar: ProgressBar
var _e_bar: ProgressBar
var _q_label: Label
var _e_label: Label
var _fragments_label: Label
var _skill_manager: Node = null
var _timer_label: Label
var _frenzy_label: Label

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

	_setup_hearts(mg, bh)
	_setup_skill_bars(mg, vp)
	_setup_fragments_label(mg, vp)
	_setup_timer_label(vp)

	ProgressionManager.xp_changed.connect(on_xp_changed)
	ProgressionManager.fragments_changed.connect(on_fragments_changed)

	on_xp_changed(
		ProgressionManager.data.current_xp,
		ProgressionManager.xp_required(ProgressionManager.data.level)
	)
	on_fragments_changed(ProgressionManager.get_fragments())

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
	if maximum > 0.0:
		health_bar.value = clampf(current / maximum * 100.0, 0.0, 100.0)
	_update_hearts(current, maximum)

func on_xp_changed(current: float, required: float) -> void:
	if required <= 0.0:
		return

	var target := clampf(current / required * 100.0, 0.0, 100.0)

	var tween := create_tween()
	tween.tween_property(_xp_bar, "value", target, 0.3).set_ease(Tween.EASE_OUT)

	_level_label.text = "Lv.%d" % ProgressionManager.data.level

func on_wave_started(wave_number: int) -> void:
	_wave_label.text = "Fase %d — Wave %d" % [ProgressionManager.get_current_area(), wave_number]

	var tween := create_tween()
	tween.tween_property(_wave_label, "modulate:a", 1.0, 0.0)
	tween.tween_property(_wave_label, "modulate:a", 0.9, 0.4)

func show_boss_label() -> void:
	if _wave_label:
		_wave_label.text = "⚔ Fase %d — BOSS ⚔" % ProgressionManager.get_current_area()
		_wave_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.15, 1.0))
	if _timer_label:
		_timer_label.hide()

func _setup_timer_label(vp: Vector2) -> void:
	_timer_label = Label.new()
	_timer_label.text = "1:30"
	_timer_label.add_theme_font_size_override("font_size", 28)
	_timer_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.position = Vector2(vp.x / 2.0 - 60.0, 12.0)
	_timer_label.size = Vector2(120.0, 36.0)
	add_child(_timer_label)

	_frenzy_label = Label.new()
	_frenzy_label.text = "⚠ FRENÉTICO ⚠"
	_frenzy_label.add_theme_font_size_override("font_size", 26)
	_frenzy_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.1, 1.0))
	_frenzy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frenzy_label.position = Vector2(vp.x / 2.0 - 120.0, 50.0)
	_frenzy_label.size = Vector2(240.0, 32.0)
	_frenzy_label.hide()
	add_child(_frenzy_label)

func on_timer_tick(remaining: float) -> void:
	if _timer_label == null:
		return
	var m := int(remaining) / 60
	var s := int(remaining) % 60
	_timer_label.text = "%d:%02d" % [m, s]
	if remaining <= 15.0:
		_timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.15, 1.0))
	else:
		_timer_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))

func on_frenzy_started() -> void:
	if _timer_label:
		_timer_label.hide()
	if _frenzy_label:
		_frenzy_label.show()

func _setup_hearts(margin: int, hp_bar_h: int) -> void:
	for i in 4:
		var lbl := Label.new()
		lbl.text = "♥"
		lbl.add_theme_font_size_override("font_size", 32)
		lbl.position = Vector2(margin + i * 36, margin)
		lbl.size = Vector2(34, hp_bar_h)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(lbl)
		_heart_labels.append(lbl)
	_update_hearts(100.0, 100.0)

func _update_hearts(current: float, maximum: float) -> void:
	if maximum <= 0.0:
		return
	var ratio := current / maximum
	for i in 4:
		var threshold := (i + 1) * 0.25
		if ratio >= threshold - 0.001:
			_heart_labels[i].add_theme_color_override("font_color", Color(0.85, 0.15, 0.15, 1.0))
		else:
			_heart_labels[i].add_theme_color_override("font_color", Color(0.35, 0.10, 0.10, 0.6))

func _setup_skill_bars(margin: int, vp: Vector2) -> void:
	# hudbar_skills.png: 1672x941 RGB (no alpha channel — white bg removed via shader)
	# expand_mode = EXPAND_IGNORE_SIZE is mandatory: without it TextureRect locks to
	# the texture's natural resolution (512px icons / 1672px hudbar) ignoring .size
	const HB_ASPECT := 1672.0 / 941.0
	# Slot fractions (adjust if icons appear offset after testing)
	const SLOT_L_X  := 0.210   # left edge of Q slot
	const SLOT_R_X  := 0.570   # left edge of E slot
	const SLOT_TOP  := 0.210   # slot top edge
	const SLOT_W    := 0.220   # slot width
	const SLOT_H    := 0.580   # slot height

	var bar_h  := 8
	var key_h  := 16
	var hb_w   := int(vp.x * 0.18)
	var hb_h   := int(round(float(hb_w) / HB_ASPECT))
	var base_y := int(vp.y) - margin - bar_h - key_h - 4 - hb_h

	# Shader: removes only the near-white RGB background (lum > 0.88)
	# Does NOT remove dark elements — keeps skulls, gems, gold border intact
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec4 col = texture(TEXTURE, UV);\n\tif (dot(col.rgb, vec3(0.299, 0.587, 0.114)) > 0.88) col.a = 0.0;\n\tCOLOR = col;\n}"
	var hb_mat := ShaderMaterial.new()
	hb_mat.shader = shader

	var hudbar_tex: Texture2D = load("res://assets/skills/hudbar/hudbar_skills.png")
	var icon_paths := [
		"res://assets/skills/craftpix_skills/PNG/27.png",
		"res://assets/skills/craftpix_skills/PNG/11.png"
	]
	var keys := ["Q", "E"]
	var slot_x_fracs := [SLOT_L_X, SLOT_R_X]

	for i in 2:
		var slot_x   := margin + int(float(hb_w) * slot_x_fracs[i])
		var slot_y   := base_y + int(float(hb_h) * SLOT_TOP)
		var slot_w   := int(float(hb_w) * SLOT_W)
		var slot_h   := int(float(hb_h) * SLOT_H)
		var icon_size: int = int(float(min(slot_w, slot_h)) * 0.82)
		var icon_x   := slot_x + (slot_w - icon_size) / 2
		var icon_y   := slot_y + (slot_h - icon_size) / 2

		# Icons at z=3 — drawn ON TOP of the dark slot fill (which is part of hudbar at z=2)
		var icon_tex: Texture2D = load(icon_paths[i])
		var icon_rect := TextureRect.new()
		icon_rect.texture = icon_tex
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_SCALE
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.z_index = 3
		add_child(icon_rect)
		icon_rect.position = Vector2(icon_x, icon_y)
		icon_rect.size = Vector2(icon_size, icon_size)

		var key_lbl := Label.new()
		key_lbl.text = keys[i]
		key_lbl.add_theme_font_size_override("font_size", 13)
		key_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_lbl.z_index = 4
		add_child(key_lbl)
		key_lbl.position = Vector2(slot_x, base_y + hb_h + 2)
		key_lbl.size = Vector2(slot_w, key_h)

		var bar := ProgressBar.new()
		bar.min_value = 0.0
		bar.max_value = 100.0
		bar.value = 100.0
		bar.show_percentage = false
		bar.z_index = 4
		add_child(bar)
		bar.position = Vector2(slot_x, base_y + hb_h + key_h + 2)
		bar.size = Vector2(slot_w, bar_h)

		var fill_sb := StyleBoxFlat.new()
		fill_sb.bg_color = Color(0.85, 0.70, 0.15, 0.85)
		fill_sb.content_margin_left = 0.0
		fill_sb.content_margin_right = 0.0
		fill_sb.content_margin_top = 0.0
		fill_sb.content_margin_bottom = 0.0
		bar.add_theme_stylebox_override("fill", fill_sb)

		var bg_sb := StyleBoxFlat.new()
		bg_sb.bg_color = Color(0.05, 0.05, 0.08, 0.6)
		bg_sb.content_margin_left = 0.0
		bg_sb.content_margin_right = 0.0
		bg_sb.content_margin_top = 0.0
		bg_sb.content_margin_bottom = 0.0
		bar.add_theme_stylebox_override("background", bg_sb)

		if i == 0:
			_q_bar = bar
			_q_label = key_lbl
		else:
			_e_bar = bar
			_e_label = key_lbl

	# Hudbar at z=2 — dark slot fill visible behind icons (z=3), frame decorations visible everywhere
	var hb_rect := TextureRect.new()
	hb_rect.texture = hudbar_tex
	hb_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hb_rect.stretch_mode = TextureRect.STRETCH_SCALE
	hb_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb_rect.z_index = 2
	hb_rect.material = hb_mat
	add_child(hb_rect)
	hb_rect.position = Vector2(margin, base_y)
	hb_rect.size = Vector2(hb_w, hb_h)

func _setup_fragments_label(margin: int, vp: Vector2) -> void:
	_fragments_label = Label.new()
	_fragments_label.text = "✦ 0"
	_fragments_label.add_theme_font_size_override("font_size", 20)
	_fragments_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.25, 1.0))
	_fragments_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fragments_label.position = Vector2(int(vp.x) - 160 - margin, margin)
	_fragments_label.size = Vector2(160, 32)
	add_child(_fragments_label)

func _process(_delta: float) -> void:
	if _skill_manager == null:
		return
	var q_ready: float = 1.0 - (_skill_manager.cooldown_q_ratio as float)
	var e_ready: float = 1.0 - (_skill_manager.cooldown_e_ratio as float)
	if _q_bar:
		_q_bar.value = q_ready * 100.0
	if _e_bar:
		_e_bar.value = e_ready * 100.0
	if _q_label:
		_q_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3) if q_ready >= 1.0 else Color(0.4, 0.4, 0.4))
	if _e_label:
		_e_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3) if e_ready >= 1.0 else Color(0.4, 0.4, 0.4))

func set_skill_manager(sm: Node) -> void:
	_skill_manager = sm

func on_fragments_changed(total: int) -> void:
	if _fragments_label:
		_fragments_label.text = "✦ %d" % total

func on_player_died() -> void:
	game_over_label.hide()
	hide()
