extends CanvasLayer

const UPGRADES := [
	{"key": "attack_damage", "label": "Dano do Ataque",  "desc": "+5 dano"},
	{"key": "skill_damage",  "label": "Dano das Skills", "desc": "+8 dano"},
	{"key": "speed",         "label": "Velocidade",      "desc": "+15 vel"},
	{"key": "max_health",    "label": "Vida Maxima",     "desc": "+20 vida"},
]

var _title: Label
var _frag_label: Label
var _buttons: Array[Button] = []

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()
	ProgressionManager.leveled_up.connect(_on_leveled_up)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.82)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bg)

	var root := CenterContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(root)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(vbox)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 36)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.modulate = Color(1.0, 0.88, 0.2)
	vbox.add_child(_title)

	_frag_label = Label.new()
	_frag_label.add_theme_font_size_override("font_size", 18)
	_frag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frag_label.modulate = Color(0.6, 0.9, 1.0)
	vbox.add_child(_frag_label)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(sep)

	for upgrade in UPGRADES:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(360, 68)
		btn.add_theme_font_size_override("font_size", 20)
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.pressed.connect(_on_upgrade_chosen.bind(upgrade["key"]))
		vbox.add_child(btn)
		_buttons.append(btn)

	var sep2 := Control.new()
	sep2.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(sep2)

	var close_btn := Button.new()
	close_btn.custom_minimum_size = Vector2(200, 48)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.text = "Fechar"
	close_btn.modulate = Color(0.7, 0.7, 0.7)
	close_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	close_btn.pressed.connect(_close)
	vbox.add_child(close_btn)

func _refresh() -> void:
	_title.text = "NIVEL %d" % ProgressionManager.data.level
	var frags := ProgressionManager.get_fragments()
	_frag_label.text = "Fragmentos da Alma: %d" % frags

	for i in _buttons.size():
		var key: String = UPGRADES[i]["key"]
		var cost := ProgressionManager.get_upgrade_cost(key)
		var can_afford := frags >= cost
		var btn := _buttons[i]
		btn.text = "%s  (%s)  —  %d fragmentos" % [
			UPGRADES[i]["label"],
			UPGRADES[i]["desc"],
			cost,
		]
		btn.disabled = not can_afford
		btn.modulate = Color(1, 1, 1) if can_afford else Color(1, 0.35, 0.35)

func _on_leveled_up(_new_level: int) -> void:
	_refresh()
	get_tree().paused = true
	show()

func _on_upgrade_chosen(attribute: String) -> void:
	ProgressionManager.apply_upgrade(attribute)
	_close()

func _close() -> void:
	get_tree().paused = false
	hide()
