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
	close_btn.pressed.connect(_close)
	vbox.add_child(close_btn)

func _make_upgrade_button(upgrade: Dictionary) -> Dictionary:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(480, 80)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
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

func _refresh() -> void:
	_title.text = "NIVEL %d" % ProgressionManager.data.level
	var frags := ProgressionManager.get_fragments()
	_frag_label.text = "Fragmentos da Alma: %d" % frags

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

func queue_level_up() -> void:
	_pending_levelups += 1

func show_queued() -> void:
	if _pending_levelups <= 0 or visible:
		return
	_pending_levelups = 0
	_refresh()
	get_tree().paused = true
	show()

func _on_upgrade_chosen(attribute: String) -> void:
	ProgressionManager.apply_upgrade(attribute)
	_refresh()

func _close() -> void:
	_pending_levelups = 0
	get_tree().paused = false
	hide()
