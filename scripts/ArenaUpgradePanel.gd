extends CanvasLayer

signal closed

const UPGRADE_POOL: Array[Dictionary] = [
	{"id": "damage",  "name": "+10% Dano de Ataque",   "desc": "Golpes e habilidades mais letais"},
	{"id": "health",  "name": "+15 Vida Máxima",        "desc": "Sobreviva por mais tempo"},
	{"id": "speed",   "name": "+10% Velocidade",        "desc": "Mova-se mais rápido"},
	{"id": "dash_cd", "name": "Dash Cooldown -0.2s",    "desc": "Esquive com mais frequência"},
]

var _player_ref: Node = null
var _buttons: Array[Dictionary] = []
var _title: Label

func _ready() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	add_child(bg)

	var root_ctrl := Control.new()
	root_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_ctrl)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(440, 0)
	root_ctrl.add_child(vbox)

	_title = Label.new()
	_title.text = "ESCOLHA UMA MELHORIA"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 42)
	_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3, 1.0))
	vbox.add_child(_title)

	var hsep := HSeparator.new()
	hsep.add_theme_color_override("color", Color(0.75, 0.63, 0.19, 0.5))
	hsep.custom_minimum_size = Vector2(400, 2)
	vbox.add_child(hsep)

	for i in 3:
		var entry: Dictionary = _make_choice_button()
		vbox.add_child(entry["btn"])
		_buttons.append(entry)

func _make_choice_button() -> Dictionary:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(480, 80)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pressed.connect(_on_choice.bind(btn))

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

	var name_lbl := Label.new()
	name_lbl.add_theme_font_size_override("font_size", 24)
	inner_vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.modulate = Color(0.8, 0.8, 0.85)
	inner_vbox.add_child(desc_lbl)

	return {"btn": btn, "name_lbl": name_lbl, "desc_lbl": desc_lbl}

func present(player: Node) -> void:
	_player_ref = player
	_randomize_choices()
	get_tree().paused = true
	show()

func _randomize_choices() -> void:
	var pool := UPGRADE_POOL.duplicate()
	pool.shuffle()
	for i in 3:
		var up: Dictionary = pool[i]
		_buttons[i]["name_lbl"].text = up["name"]
		_buttons[i]["desc_lbl"].text = up["desc"]
		_buttons[i]["btn"].set_meta("upgrade_id", up["id"])

func _on_choice(btn: Button) -> void:
	var uid: String = btn.get_meta("upgrade_id")
	if _player_ref and _player_ref.has_method("apply_temp_upgrade"):
		_player_ref.apply_temp_upgrade(uid)
	get_tree().paused = false
	hide()
	closed.emit()
