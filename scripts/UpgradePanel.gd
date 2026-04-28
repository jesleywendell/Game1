extends CanvasLayer

const UPGRADES := [
	{"key": "attack_damage", "label": "Dano do Ataque",   "desc": "+5 por ponto"},
	{"key": "skill_damage",  "label": "Dano das Skills",   "desc": "+8 por ponto"},
	{"key": "speed",         "label": "Velocidade",        "desc": "+15 por ponto"},
	{"key": "max_health",    "label": "Vida Maxima",       "desc": "+20 por ponto"},
]

var _title: Label
var _subtitle: Label

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()
	ProgressionManager.leveled_up.connect(_on_leveled_up)
	ProgressionManager.upgrade_applied.connect(_on_upgrade_applied)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.82)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bg)

	var root := CenterContainer.new()
	root.anchors_preset = Control.PRESET_FULL_RECT
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

	_subtitle = Label.new()
	_subtitle.add_theme_font_size_override("font_size", 16)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.modulate = Color(0.75, 0.75, 0.75)
	vbox.add_child(_subtitle)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(sep)

	for upgrade in UPGRADES:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(360, 68)
		btn.add_theme_font_size_override("font_size", 20)
		btn.text = "%s  (%s)" % [upgrade["label"], upgrade["desc"]]
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.pressed.connect(_on_upgrade_chosen.bind(upgrade["key"]))
		vbox.add_child(btn)

func _refresh() -> void:
	_title.text    = "NIVEL %d" % ProgressionManager.data.level
	_subtitle.text = "%d ponto(s) de habilidade disponivel(is)" % ProgressionManager.data.skill_points

func _on_leveled_up(_new_level: int) -> void:
	_refresh()
	get_tree().paused = true
	show()

func _on_upgrade_chosen(attribute: String) -> void:
	ProgressionManager.apply_upgrade(attribute)

func _on_upgrade_applied() -> void:
	if ProgressionManager.data.skill_points > 0:
		_refresh()
		return
	get_tree().paused = false
	hide()
