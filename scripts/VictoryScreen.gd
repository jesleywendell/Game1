extends CanvasLayer

var enemies_killed    := 0
var run_start_ms      := 0
var fragments_at_start := 0

func setup(ek: int, rs: int, fs: int) -> void:
	enemies_killed     = ek
	run_start_ms       = rs
	fragments_at_start = fs
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var frags_earned  := ProgressionManager.get_fragments() - fragments_at_start
	var elapsed_sec   := int((Time.get_ticks_msec() - run_start_ms) / 1000)
	var minutes       := elapsed_sec / 60
	var seconds       := elapsed_sec % 60
	var vp            := get_viewport().get_visible_rect().size

	# Full background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.02, 0.02, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.process_mode = Node.PROCESS_MODE_ALWAYS
	bg.modulate.a = 0.0
	add_child(bg)

	# Amber horizontal rule — top accent
	var rule_top := ColorRect.new()
	rule_top.set_position(Vector2(vp.x * 0.20, vp.y * 0.18))
	rule_top.set_size(Vector2(vp.x * 0.60, 2.0))
	rule_top.color = Color(0.65, 0.42, 0.10, 0.8)
	rule_top.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(rule_top)

	# Amber horizontal rule — bottom accent
	var rule_bot := ColorRect.new()
	rule_bot.set_position(Vector2(vp.x * 0.20, vp.y * 0.82))
	rule_bot.set_size(Vector2(vp.x * 0.60, 2.0))
	rule_bot.color = Color(0.65, 0.42, 0.10, 0.8)
	rule_bot.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(rule_bot)

	# Title
	var title := Label.new()
	title.text = "OATHBREAKER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.80, 0.30, 0.15))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.set_position(Vector2(0.0, vp.y * 0.20))
	title.set_size(Vector2(vp.x, 70.0))
	title.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(title)

	# Subtitle
	var sub := Label.new()
	sub.text = "\"A redenção não é perdão.\nÉ a escolha de continuar.\""
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.75, 0.70, 0.58))
	sub.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	sub.add_theme_constant_override("shadow_offset_x", 2)
	sub.add_theme_constant_override("shadow_offset_y", 2)
	sub.set_position(Vector2(0.0, vp.y * 0.34))
	sub.set_size(Vector2(vp.x, 60.0))
	sub.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sub)

	# Stats
	var stats_lines: Array[String] = [
		"Inimigos derrotados: %d"  % enemies_killed,
		"Fragmentos coletados: %d" % maxi(0, frags_earned),
		"Tempo total: %dm %02ds"   % [minutes, seconds],
	]
	var sy := vp.y * 0.52
	for s in stats_lines:
		var lbl := Label.new()
		lbl.text = s
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.70))
		lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
		lbl.add_theme_constant_override("shadow_offset_x", 2)
		lbl.add_theme_constant_override("shadow_offset_y", 2)
		lbl.set_position(Vector2(0.0, sy))
		lbl.set_size(Vector2(vp.x, 28.0))
		lbl.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(lbl)
		sy += 30.0

	# Buttons
	var bw := vp.x * 0.22
	var bh := 48.0
	var gap := 18.0
	var total_w := bw * 2.0 + gap
	var bx := (vp.x - total_w) * 0.5
	var by := vp.y * 0.70

	_make_btn("Novo Jogo+", Color(0.70, 0.48, 0.12), bx, by, bw, bh, func():
		ProgressionManager.reset()
		get_tree().paused = false
		TransitionScreen.fade_to("res://scenes/World.tscn")
	)
	_make_btn("Menu Principal", Color(0.38, 0.34, 0.28), bx + bw + gap, by, bw, bh, func():
		get_tree().paused = false
		TransitionScreen.fade_to("res://scenes/MainMenu.tscn")
	)

	# Fade in entire layer
	var tw := create_tween()
	tw.set_process_mode(Tween.TWEEN_PROCESS_ALWAYS)
	tw.tween_property(bg, "modulate:a", 1.0, 0.8)

func _make_btn(label_text: String, col: Color, x: float, y: float, w: float, h: float, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = label_text
	btn.set_position(Vector2(x, y))
	btn.set_size(Vector2(w, h))
	btn.process_mode = Node.PROCESS_MODE_ALWAYS

	var normal := StyleBoxFlat.new()
	normal.bg_color = col
	normal.border_width_bottom = 3
	normal.border_color = col.lightened(0.3)
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = col.lightened(0.18)
	hover.border_width_bottom = 3
	hover.border_color = col.lightened(0.5)
	hover.corner_radius_top_left = 4
	hover.corner_radius_top_right = 4
	hover.corner_radius_bottom_left = 4
	hover.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", Color(0.95, 0.92, 0.80))
	btn.pressed.connect(cb)
	add_child(btn)
