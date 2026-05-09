extends CanvasLayer

const UPGRADES := [
	{"key": "attack_damage", "label": "Dano do Ataque",  "desc": "+5 dano",  "symbol": "⚔"},
	{"key": "skill_damage",  "label": "Dano das Skills", "desc": "+8 dano",  "symbol": "✦"},
	{"key": "speed",         "label": "Velocidade",      "desc": "+15 vel",  "symbol": "≫"},
	{"key": "max_health",    "label": "Vida Maxima",     "desc": "+20 vida", "symbol": "♥"},
]

var _title: Label
var _frag_label: Label
var _buttons: Array[Dictionary] = []
var _pending_levelups: int = 0
var _tutorial_panel: Control
var _tutorial_dismissed: bool = false
var _pulse_tweens: Array[Tween] = []
var _root: Control
var _btn_container: VBoxContainer

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bg)

	var bg_tex := TextureRect.new()
	bg_tex.texture = load("res://assets/game_over/background/background_game_over_02.png")
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_SCALE
	bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_tex.modulate = Color(1.0, 1.0, 1.0, 0.18)
	bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_tex)

	var root := CenterContainer.new()
	_root = root
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(root)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(vbox)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 52)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.modulate = Color(0.95, 0.85, 0.3)
	vbox.add_child(_title)

	var subtitle := Label.new()
	subtitle.text = "— Você Evoluiu —"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.65, 0.55, 0.25, 0.8))
	vbox.add_child(subtitle)

	var hsep := HSeparator.new()
	hsep.add_theme_color_override("color", Color(0.75, 0.63, 0.19, 0.5))
	hsep.custom_minimum_size = Vector2(400, 2)
	vbox.add_child(hsep)

	var frag_box := PanelContainer.new()
	var frag_style := StyleBoxFlat.new()
	frag_style.bg_color = Color(0.10, 0.08, 0.03, 0.75)
	frag_style.border_color = Color(0.75, 0.63, 0.19, 0.5)
	frag_style.border_width_top = 2
	frag_style.border_width_bottom = 2
	frag_style.border_width_left = 2
	frag_style.border_width_right = 2
	frag_style.corner_radius_top_left = 6
	frag_style.corner_radius_top_right = 6
	frag_style.corner_radius_bottom_left = 6
	frag_style.corner_radius_bottom_right = 6
	frag_box.add_theme_stylebox_override("panel", frag_style)
	vbox.add_child(frag_box)

	var frag_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		frag_margin.add_theme_constant_override("margin_" + side, 8)
	frag_box.add_child(frag_margin)

	_frag_label = Label.new()
	_frag_label.add_theme_font_size_override("font_size", 20)
	_frag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frag_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.25))
	frag_margin.add_child(_frag_label)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(sep)

	var btn_panel := PanelContainer.new()
	var btn_panel_style := StyleBoxFlat.new()
	btn_panel_style.bg_color = Color(0.04, 0.04, 0.08, 0.5)
	btn_panel_style.border_color = Color(0.75, 0.63, 0.19, 0.35)
	btn_panel_style.border_width_top = 1
	btn_panel_style.border_width_bottom = 1
	btn_panel_style.border_width_left = 1
	btn_panel_style.border_width_right = 1
	btn_panel_style.corner_radius_top_left = 6
	btn_panel_style.corner_radius_top_right = 6
	btn_panel_style.corner_radius_bottom_left = 6
	btn_panel_style.corner_radius_bottom_right = 6
	vbox.add_child(btn_panel)

	var btn_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		btn_margin.add_theme_constant_override("margin_" + side, 10)
	btn_panel.add_child(btn_margin)

	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 10)
	btn_margin.add_child(btn_vbox)
	_btn_container = btn_vbox

	_tutorial_panel = _build_tutorial()
	vbox.add_child(_tutorial_panel)

	for upgrade in UPGRADES:
		var entry: Dictionary = _make_upgrade_button(upgrade)
		_btn_container.add_child(entry["btn"])
		_buttons.append(entry)

	var close_btn := Button.new()
	close_btn.custom_minimum_size = Vector2(200, 48)
	close_btn.text = "✕   Fechar"
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(0.70, 0.60, 0.25))
	close_btn.process_mode = Node.PROCESS_MODE_ALWAYS

	var close_normal := StyleBoxFlat.new()
	close_normal.bg_color = Color(0.06, 0.06, 0.10, 0.9)
	close_normal.border_color = Color(0.65, 0.52, 0.15, 0.55)
	close_normal.border_width_top = 3
	close_normal.border_width_left = 1
	close_normal.border_width_right = 1
	close_normal.border_width_bottom = 1
	close_normal.corner_radius_top_left = 6
	close_normal.corner_radius_top_right = 6
	close_normal.corner_radius_bottom_left = 6
	close_normal.corner_radius_bottom_right = 6
	close_btn.add_theme_stylebox_override("normal", close_normal)

	var close_hover := StyleBoxFlat.new()
	close_hover.bg_color = Color(0.10, 0.08, 0.04, 0.95)
	close_hover.border_color = Color(0.90, 0.75, 0.20, 0.8)
	close_hover.border_width_top = 3
	close_hover.border_width_left = 1
	close_hover.border_width_right = 1
	close_hover.border_width_bottom = 1
	close_hover.corner_radius_top_left = 6
	close_hover.corner_radius_top_right = 6
	close_hover.corner_radius_bottom_left = 6
	close_hover.corner_radius_bottom_right = 6
	close_btn.add_theme_stylebox_override("hover", close_hover)

	close_btn.mouse_entered.connect(AudioManager.play_btn_hover)
	close_btn.pressed.connect(AudioManager.play_btn_click)
	close_btn.pressed.connect(_close)
	vbox.add_child(close_btn)

func _make_upgrade_button(upgrade: Dictionary) -> Dictionary:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(480, 90)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.mouse_entered.connect(AudioManager.play_btn_hover)
	btn.mouse_entered.connect(func():
		if btn.disabled:
			return
		var t := btn.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.08).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var t := btn.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_ease(Tween.EASE_IN)
	)
	btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)
	btn.pressed.connect(AudioManager.play_btn_click)
	btn.pressed.connect(_on_upgrade_chosen.bind(upgrade["key"]))

	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = Color(0.12, 0.12, 0.22, 0.9)
	normal_sb.border_color = Color(0.75, 0.63, 0.19, 0.75)
	normal_sb.border_width_left = 2
	normal_sb.border_width_right = 2
	normal_sb.border_width_top = 4
	normal_sb.border_width_bottom = 2
	normal_sb.corner_radius_top_left = 8
	normal_sb.corner_radius_top_right = 8
	normal_sb.corner_radius_bottom_left = 8
	normal_sb.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", normal_sb)

	var hover_sb := StyleBoxFlat.new()
	hover_sb.bg_color = Color(0.18, 0.18, 0.32, 0.95)
	hover_sb.border_color = Color(0.95, 0.85, 0.3, 0.8)
	hover_sb.border_width_left = 2
	hover_sb.border_width_right = 2
	hover_sb.border_width_top = 4
	hover_sb.border_width_bottom = 2
	hover_sb.corner_radius_top_left = 8
	hover_sb.corner_radius_top_right = 8
	hover_sb.corner_radius_bottom_left = 8
	hover_sb.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("hover", hover_sb)

	var disabled_sb := StyleBoxFlat.new()
	disabled_sb.bg_color = Color(0.08, 0.08, 0.12, 0.7)
	disabled_sb.border_color = Color(0.6, 0.15, 0.15, 0.5)
	disabled_sb.border_width_left = 2
	disabled_sb.border_width_right = 2
	disabled_sb.border_width_top = 2
	disabled_sb.border_width_bottom = 2
	disabled_sb.corner_radius_top_left = 8
	disabled_sb.corner_radius_top_right = 8
	disabled_sb.corner_radius_bottom_left = 8
	disabled_sb.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("disabled", disabled_sb)

	var outer_hbox := HBoxContainer.new()
	outer_hbox.add_theme_constant_override("separation", 14)
	btn.add_child(outer_hbox)

	var sym_lbl := Label.new()
	sym_lbl.text = upgrade["symbol"]
	sym_lbl.add_theme_font_size_override("font_size", 46)
	sym_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.25))
	sym_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sym_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sym_lbl.custom_minimum_size = Vector2(64, 64)
	sym_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_hbox.add_child(sym_lbl)

	var inner_vbox := VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 2)
	inner_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	outer_hbox.add_child(inner_vbox)

	var title_lbl := Label.new()
	title_lbl.add_theme_font_size_override("font_size", 27)
	title_lbl.text = upgrade["label"]
	inner_vbox.add_child(title_lbl)

	var dots_hbox := HBoxContainer.new()
	dots_hbox.add_theme_constant_override("separation", 4)
	inner_vbox.add_child(dots_hbox)

	var dot_labels: Array[Label] = []
	for d in 5:
		var dot := Label.new()
		dot.text = "■"
		dot.add_theme_font_size_override("font_size", 10)
		dot.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dots_hbox.add_child(dot)
		dot_labels.append(dot)

	var bottom_hbox := HBoxContainer.new()
	inner_vbox.add_child(bottom_hbox)

	var desc_lbl := Label.new()
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.modulate = Color(0.8, 0.8, 0.85)
	desc_lbl.text = upgrade["desc"]
	bottom_hbox.add_child(desc_lbl)

	var cost_spacer := Control.new()
	cost_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(cost_spacer)

	var cost_lbl := Label.new()
	cost_lbl.add_theme_font_size_override("font_size", 18)
	cost_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.25))
	bottom_hbox.add_child(cost_lbl)

	return {"btn": btn, "title_lbl": title_lbl, "desc_lbl": desc_lbl, "cost_lbl": cost_lbl, "sym_lbl": sym_lbl, "dots": dot_labels}

func _build_tutorial() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.04, 0.92)
	style.border_color = Color(0.85, 0.60, 0.10, 0.75)
	style.border_width_top = 3
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	margin.add_child(inner)

	var header := Label.new()
	header.text = "◆ COMO FUNCIONAM OS UPGRADES ◆"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 15)
	header.modulate = Color(0.95, 0.78, 0.20)
	inner.add_child(header)

	var line1 := Label.new()
	line1.text = "• Você pode comprar mais de um upgrade antes de fechar o painel — não há limite por nível."
	line1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line1.add_theme_font_size_override("font_size", 14)
	line1.modulate = Color(0.90, 0.90, 0.90)
	inner.add_child(line1)

	var line2 := Label.new()
	line2.text = "• Atenção: cada upgrade fica progressivamente mais caro. Não gaste todos os seus Fragmentos de Alma de uma vez — você vai precisar deles."
	line2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line2.add_theme_font_size_override("font_size", 14)
	line2.modulate = Color(0.95, 0.55, 0.25)
	inner.add_child(line2)

	var dismiss_btn := Button.new()
	dismiss_btn.text = "Entendido"
	dismiss_btn.custom_minimum_size = Vector2(140, 34)
	dismiss_btn.add_theme_font_size_override("font_size", 14)
	dismiss_btn.modulate = Color(0.85, 0.72, 0.30)
	dismiss_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	dismiss_btn.mouse_entered.connect(AudioManager.play_btn_hover)
	dismiss_btn.pressed.connect(AudioManager.play_btn_click)
	dismiss_btn.pressed.connect(func():
		_tutorial_dismissed = true
		panel.hide()
	)
	var btn_center := CenterContainer.new()
	btn_center.add_child(dismiss_btn)
	inner.add_child(btn_center)

	panel.hide()
	return panel

func _refresh() -> void:
	_title.text = "✦  NIVEL %d  ✦" % ProgressionManager.data.level
	var frags := ProgressionManager.get_fragments()
	_frag_label.text = "◆  %d  Fragmentos da Alma" % frags

	if not _tutorial_dismissed and ProgressionManager.data.level == 2:
		_tutorial_panel.show()

	for i in _buttons.size():
		var key: String = UPGRADES[i]["key"]
		var cost := ProgressionManager.get_upgrade_cost(key)
		var can_afford := frags >= cost
		var entry := _buttons[i]
		entry["btn"].disabled = not can_afford
		entry["cost_lbl"].text = "%d fragmentos" % cost
		var level_v = ProgressionManager.data.get(key + "_upgrades")
		var level: int = int(level_v) if level_v != null else 0
		var dots: Array = entry["dots"]
		for d in 5:
			var dot_color := Color(0.95, 0.82, 0.25) if d < level else Color(0.28, 0.28, 0.32)
			dots[d].add_theme_color_override("font_color", dot_color)
		if can_afford:
			entry["title_lbl"].modulate = Color(1, 1, 1)
			entry["desc_lbl"].modulate = Color(0.8, 0.8, 0.85)
			entry["cost_lbl"].modulate = Color(0.95, 0.85, 0.3)
			entry["sym_lbl"].add_theme_color_override("font_color", Color(0.95, 0.82, 0.25))
		else:
			entry["title_lbl"].modulate = Color(0.8, 0.25, 0.25)
			entry["desc_lbl"].modulate = Color(0.8, 0.25, 0.25)
			entry["cost_lbl"].modulate = Color(0.8, 0.25, 0.25)
			entry["sym_lbl"].add_theme_color_override("font_color", Color(0.55, 0.2, 0.2, 0.9))

func _animate_in() -> void:
	_root.modulate.a = 0.0
	var fade := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(_root, "modulate:a", 1.0, 0.35).set_ease(Tween.EASE_OUT)

	_title.pivot_offset = _title.size / 2.0
	_title.scale = Vector2(2.0, 2.0)
	var title_t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	title_t.tween_property(_title, "scale", Vector2(1.0, 1.0), 0.55)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	for i in _buttons.size():
		var btn: Button = _buttons[i]["btn"]
		btn.modulate = Color(0.0, 0.0, 0.0, 0.0)
		btn.pivot_offset = btn.size / 2.0
		btn.scale = Vector2(0.88, 0.88)
		var bt := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		bt.tween_interval(0.10 + i * 0.09)
		bt.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.28)\
			.set_ease(Tween.EASE_OUT)
		var bs := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		bs.tween_interval(0.10 + i * 0.09)
		bs.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.30)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	_stop_pulses()
	for i in _buttons.size():
		var sym: Label = _buttons[i]["sym_lbl"]
		sym.pivot_offset = Vector2(32.0, 32.0)
		var pt := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_loops()
		var phase_offset := i * 0.18
		pt.tween_interval(phase_offset)
		pt.tween_property(sym, "scale", Vector2(1.13, 1.13), 0.85)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		pt.tween_property(sym, "scale", Vector2(1.0, 1.0), 0.85)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_pulse_tweens.append(pt)

func _stop_pulses() -> void:
	for t in _pulse_tweens:
		if t and t.is_valid():
			t.kill()
	_pulse_tweens.clear()

func on_leveled_up() -> void:
	if visible:
		_pending_levelups += 1
		return
	_refresh()
	get_tree().paused = true
	show()
	_animate_in()

func _on_upgrade_chosen(attribute: String) -> void:
	ProgressionManager.apply_upgrade(attribute)
	for i in _buttons.size():
		if UPGRADES[i]["key"] == attribute:
			var btn: Button = _buttons[i]["btn"]
			btn.modulate = Color(1.6, 1.3, 0.3, 1.0)
			var flash := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			flash.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.45)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			break
	_refresh()

func _close() -> void:
	_stop_pulses()
	var fade := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(_root, "modulate:a", 0.0, 0.18).set_ease(Tween.EASE_IN)
	fade.tween_callback(func():
		get_tree().paused = false
		_root.modulate.a = 1.0
		hide()
		if _pending_levelups > 0:
			_pending_levelups -= 1
			_refresh()
			get_tree().paused = true
			show()
			_animate_in()
	)
