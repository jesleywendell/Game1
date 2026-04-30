extends CanvasLayer

signal closed

const UPGRADE_POOL: Array[Dictionary] = [
	{"id": "damage",  "name": "+10% Dano de Ataque",   "desc": "Golpes e habilidades mais letais"},
	{"id": "health",  "name": "+15 Vida Máxima",        "desc": "Sobreviva por mais tempo"},
	{"id": "speed",   "name": "+10% Velocidade",        "desc": "Mova-se mais rápido"},
	{"id": "dash_cd", "name": "Dash Cooldown -0.2s",    "desc": "Esquive com mais frequência"},
]

var _player_ref: Node = null
var _buttons: Array[Button] = []

func _ready() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.72)
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

	var title := Label.new()
	title.text = "ESCOLHA UMA MELHORIA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3, 1.0))
	vbox.add_child(title)

	for i in 3:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(380, 64)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_choice.bind(btn))
		vbox.add_child(btn)
		_buttons.append(btn)

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
		_buttons[i].text = up["name"] + "\n" + up["desc"]
		_buttons[i].set_meta("upgrade_id", up["id"])

func _on_choice(btn: Button) -> void:
	var uid: String = btn.get_meta("upgrade_id")
	if _player_ref and _player_ref.has_method("apply_temp_upgrade"):
		_player_ref.apply_temp_upgrade(uid)
	get_tree().paused = false
	hide()
	closed.emit()
