extends CanvasLayer

const UPGRADES := [
	{"key": "attack_damage", "label": "Dano do Ataque",  "desc": "+5 dano"},
	{"key": "skill_damage",  "label": "Dano das Skills", "desc": "+8 dano"},
	{"key": "speed",         "label": "Velocidade",      "desc": "+15 vel"},
	{"key": "max_health",    "label": "Vida Maxima",     "desc": "+20 vida"},
]

var _title: Label
var _frag_label: Label
var _buttons: Array[Dictionary] = []
var _pending_levelups: int = 0
var _tutorial_panel: Control
var _tutorial_dismissed: bool = false

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

	var root := CenterContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(root)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(vbox)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 42)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.modulate = Color(0.95, 0.85, 0.3)
	vbox.add_child(_title)

	var hsep := HSeparator.new()
	hsep.add_theme_color_override("color", Color(0.75, 0.63, 0.19, 0.5))
	hsep.custom_minimum_size = Vector2(400, 2)
	vbox.add_child(hsep)

	_frag_label = Label.new()
	_frag_label.add_theme_font_size_override("font_size", 18)
	_frag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frag_label.modulate = Color(0.6, 0.9, 1.0)
	vbox.add_child(_frag_label)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(sep)

	_tutorial_panel = _build_tutorial()
	vbox.add_child(_tutorial_panel)

	for upgrade in UPGRADES:
		var entry: Dictionary = _make_upgrade_button(upgrade)
		vbox.add_child(entry["btn"])
		_buttons.append(entry)

	var close_btn := Button.new()
	close_btn.custom_minimum_size = Vector2(200, 48)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.text = "Fechar"
	close_btn.modulate = Color(0.7, 0.7, 0.7)
	close_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	close_btn.mouse_entered.connect(AudioManager.play_btn_hover)
	close_btn.pressed.connect(AudioManager.play_btn_click)
	close_btn.pressed.connect(_close)
	vbox.add_child(close_btn)

func _make_upgrade_button(upgrade: Dictionary) -> Dictionary:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(480, 80)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.mouse_entered.connect(AudioManager.play_btn_hover)
	btn.pressed.connect(AudioManager.play_btn_click)
	btn.pressed.connect(_on_upgrade_chosen.bind(upgrade["key"]))

	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = Color(0.12, 0.12, 0.22, 0.9)
	normal_sb.border_color = Color(0.75, 0.63, 0.19, 0.5)
	normal_sb.border_width_left = 2
	normal_sb.border_width_right = 2
	normal_sb.border_width_top = 2
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
	hover_sb.border_width_top = 2
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

	var inner_vbox := VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 2)
	btn.add_child(inner_vbox)

	var title_lbl := Label.new()
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.text = upgrade["label"]
	inner_vbox.add_child(title_lbl)

	var bottom_hbox := HBoxContainer.new()
	inner_vbox.add_child(bottom_hbox)

	var desc_lbl := Label.new()
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.modulate = Color(0.8, 0.8, 0.85)
	desc_lbl.text = upgrade["desc"]
	bottom_hbox.add_child(desc_lbl)

	var cost_spacer := Control.new()
	cost_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(cost_spacer)

	var cost_lbl := Label.new()
	cost_lbl.add_theme_font_size_override("font_size", 16)
	cost_lbl.modulate = Color(0.95, 0.85, 0.3)
	bottom_hbox.add_child(cost_lbl)

	return {"btn": btn, "title_lbl": title_lbl, "desc_lbl": desc_lbl, "cost_lbl": cost_lbl}

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
	_title.text = "NIVEL %d" % ProgressionManager.data.level
	var frags := ProgressionManager.get_fragments()
	_frag_label.text = "Fragmentos da Alma: %d" % frags

	if not _tutorial_dismissed and ProgressionManager.data.level == 2:
		_tutorial_panel.show()

	for i in _buttons.size():
		var key: String = UPGRADES[i]["key"]
		var cost := ProgressionManager.get_upgrade_cost(key)
		var can_afford := frags >= cost
		var entry := _buttons[i]
		entry["btn"].disabled = not can_afford
		entry["cost_lbl"].text = "%d fragmentos" % cost
		if can_afford:
			entry["title_lbl"].modulate = Color(1, 1, 1)
			entry["desc_lbl"].modulate = Color(0.8, 0.8, 0.85)
			entry["cost_lbl"].modulate = Color(0.95, 0.85, 0.3)
		else:
			entry["title_lbl"].modulate = Color(0.8, 0.25, 0.25)
			entry["desc_lbl"].modulate = Color(0.8, 0.25, 0.25)
			entry["cost_lbl"].modulate = Color(0.8, 0.25, 0.25)

func on_leveled_up() -> void:
	if visible:
		_pending_levelups += 1
		return
	_refresh()
	get_tree().paused = true
	show()

func _on_upgrade_chosen(attribute: String) -> void:
	ProgressionManager.apply_upgrade(attribute)
	_refresh()

func _close() -> void:
	get_tree().paused = false
	hide()
	if _pending_levelups > 0:
		_pending_levelups -= 1
		_refresh()
		get_tree().paused = true
		show()
