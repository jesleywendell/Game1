extends CanvasLayer

signal dialogue_finished

const CHAR_DELAY := 0.025

const BOSS_COLORS := {
	"CAVALEIRO CORRUPTO": Color(0.95, 0.62, 0.22),
	"TRISS":              Color(0.70, 0.48, 1.00),
	"JESS LEYMOS-KAA":   Color(1.00, 0.22, 0.22),
	"AZRAEL":            Color(0.48, 0.76, 1.00),
}

static func get_death_lines(area: int) -> Array[Dictionary]:
	match area:
		3:
			return [
				{speaker = "JESS LEYMOS-KAA", text = "Você sobreviveu."},
				{speaker = "JESS LEYMOS-KAA", text = "Eu não disse que estava certo."},
				{speaker = "JESS LEYMOS-KAA", text = "Disse que estava cansado."},
				{speaker = "AZRAEL",           text = "..."},
				{speaker = "JESS LEYMOS-KAA", text = "Cuide de Kaerlid, perjurador."},
				{speaker = "JESS LEYMOS-KAA", text = "Não porque você merece."},
				{speaker = "JESS LEYMOS-KAA", text = "Mas porque agora é só você que resta."},
			]
	return []

var auto_unpause := true

static func get_lines(area: int) -> Array[Dictionary]:
	match area:
		1:
			return [
				{speaker = "CAVALEIRO CORRUPTO", text = "Azrael."},
				{speaker = "CAVALEIRO CORRUPTO", text = "Eu te reconheço, perjurador."},
				{speaker = "CAVALEIRO CORRUPTO", text = "Servi à mesma Igreja que você jurou proteger."},
				{speaker = "CAVALEIRO CORRUPTO", text = "Quando você quebrou o juramento... eu vi o que restou de Kaerlid."},
				{speaker = "CAVALEIRO CORRUPTO", text = "Não sobrou nada sagrado. Só corrupção."},
				{speaker = "CAVALEIRO CORRUPTO", text = "Igual a você."},
				{speaker = "AZRAEL",             text = "Eu sei o que sou."},
				{speaker = "AZRAEL",             text = "Mas ainda estou de pé."},
				{speaker = "CAVALEIRO CORRUPTO", text = "Por quanto tempo?"},
				{speaker = "CAVALEIRO CORRUPTO", text = "Venha então, perjurador. Vou te enviar de volta à vala que você merece."},
			]
		2:
			return [
				{speaker = "TRISS",  text = "Você ainda usa os dons sagrados."},
				{speaker = "TRISS",  text = "Veja suas mãos."},
				{speaker = "TRISS",  text = "Eles te consomem porque te rejeitam."},
				{speaker = "AZRAEL", text = "Triss. O que ele fez com você?"},
				{speaker = "TRISS",  text = "A verdade. Algo que os deuses nunca te deram."},
				{speaker = "TRISS",  text = "Eu fui guardiã dessa floresta antes de Jess me encontrar."},
				{speaker = "TRISS",  text = "Kaerlid não foi amaldiçoado por ódio, Azrael."},
				{speaker = "TRISS",  text = "Foi abandonado pela fé. A mesma fé que você destruiu."},
				{speaker = "AZRAEL", text = "Eu errei. Mas não vou deixar que isso defina o que vem depois."},
				{speaker = "TRISS",  text = "Palavras bonitas para alguém que sangra pelos próprios poderes."},
				{speaker = "TRISS",  text = "Não vou deixar você passar."},
			]
		3:
			return [
				{speaker = "",               text = "..."},
				{speaker = "JESS LEYMOS-KAA", text = "Você chegou mais longe do que eu esperava."},
				{speaker = "JESS LEYMOS-KAA", text = "Curioso."},
				{speaker = "JESS LEYMOS-KAA", text = "Eu conheço seu juramento, Azrael. Sei o que você prometeu."},
				{speaker = "JESS LEYMOS-KAA", text = "Sei o que você escolheu no lugar disso."},
				{speaker = "JESS LEYMOS-KAA", text = "Kaerlid morreu porque pessoas como você decidiram que o juramento era inconveniente."},
				{speaker = "AZRAEL",           text = "Eu errei. Não vou negar isso."},
				{speaker = "JESS LEYMOS-KAA", text = "Eu não amaldiçoei este mundo por ódio."},
				{speaker = "JESS LEYMOS-KAA", text = "Eu amaldiçoei porque vi o que ele era quando ninguém estava olhando."},
				{speaker = "JESS LEYMOS-KAA", text = "Podre. Covarde. Vazio."},
				{speaker = "AZRAEL",           text = "..."},
				{speaker = "AZRAEL",           text = "Talvez você tenha razão."},
				{speaker = "AZRAEL",           text = "Mas alguém precisa ficar. E eu escolho ser esse alguém."},
				{speaker = "JESS LEYMOS-KAA", text = "Venha então, perjurador."},
				{speaker = "JESS LEYMOS-KAA", text = "Me convença de que estou errada."},
			]
	return []

var _lines: Array[Dictionary] = []
var _current_line := 0
var _typing := false
var _full_text := ""
var _displayed_chars := 0
var _char_timer := 0.0
var _waiting_for_input := false
var _panel: Control
var _speaker_label: Label
var _text_label: Label
var _hint_label: Label
var _border_top: ColorRect
var _border_bot: ColorRect

func setup(lines: Array[Dictionary]) -> void:
	_lines = lines
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	_build_ui()
	get_tree().paused = true
	_show_line(0)

func _build_ui() -> void:
	var vp := get_viewport().get_visible_rect().size

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.50)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)

	var panel_w := vp.x * 0.72
	var panel_h := vp.y * 0.30
	var panel_x := (vp.x - panel_w) * 0.5
	var panel_y := vp.y - panel_h - vp.y * 0.06

	_panel = Control.new()
	_panel.set_position(Vector2(panel_x, panel_y))
	_panel.set_size(Vector2(panel_w, panel_h))
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.modulate.a = 0.0
	add_child(_panel)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.02, 0.02, 0.95)
	bg.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.add_child(bg)

	_border_top = ColorRect.new()
	_border_top.set_position(Vector2(0.0, 0.0))
	_border_top.set_size(Vector2(panel_w, 3.0))
	_border_top.color = Color(0.60, 0.40, 0.12, 0.9)
	_panel.add_child(_border_top)

	_border_bot = ColorRect.new()
	_border_bot.set_position(Vector2(0.0, panel_h - 3.0))
	_border_bot.set_size(Vector2(panel_w, 3.0))
	_border_bot.color = Color(0.60, 0.40, 0.12, 0.9)
	_panel.add_child(_border_bot)

	var vbox := VBoxContainer.new()
	vbox.set_position(Vector2(28.0, 16.0))
	vbox.set_size(Vector2(panel_w - 56.0, panel_h - 32.0))
	vbox.add_theme_constant_override("separation", 8)
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.add_child(vbox)

	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 15)
	_speaker_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
	_speaker_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	_speaker_label.add_theme_constant_override("shadow_offset_x", 2)
	_speaker_label.add_theme_constant_override("shadow_offset_y", 2)
	_speaker_label.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(_speaker_label)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0.0, 1.0)
	sep.color = Color(0.4, 0.28, 0.08, 0.55)
	sep.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(sep)

	_text_label = Label.new()
	_text_label.add_theme_font_size_override("font_size", 19)
	_text_label.add_theme_color_override("font_color", Color(0.93, 0.89, 0.76))
	_text_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	_text_label.add_theme_constant_override("shadow_offset_x", 2)
	_text_label.add_theme_constant_override("shadow_offset_y", 2)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(_text_label)

	_hint_label = Label.new()
	_hint_label.text = "[ pressione qualquer tecla ]"
	_hint_label.add_theme_font_size_override("font_size", 12)
	_hint_label.add_theme_color_override("font_color", Color(0.55, 0.50, 0.38, 0.65))
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.visible = false
	_hint_label.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(_hint_label)

	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, 0.45)

func _show_line(index: int) -> void:
	if index >= _lines.size():
		_finish()
		return

	var entry := _lines[index]
	var speaker: String = entry.get("speaker", "")
	var text: String = entry.get("text", "")
	var color: Color = BOSS_COLORS.get(speaker, Color(0.93, 0.89, 0.76))

	if speaker.is_empty():
		_speaker_label.text = "◆   ◆   ◆"
		_speaker_label.add_theme_color_override("font_color", Color(0.45, 0.42, 0.33, 0.7))
		_set_border_color(Color(0.35, 0.30, 0.20, 0.7))
	else:
		_speaker_label.text = "— " + speaker + " —"
		_speaker_label.add_theme_color_override("font_color", color)
		_set_border_color(color * 0.7)

	if speaker == "AZRAEL":
		_text_label.add_theme_color_override("font_color", Color(0.75, 0.88, 1.00))
	else:
		_text_label.add_theme_color_override("font_color", Color(0.93, 0.89, 0.76))

	_text_label.text = ""
	_hint_label.visible = false
	_full_text = text
	_displayed_chars = 0
	_char_timer = 0.0
	_typing = true
	_waiting_for_input = false

func _set_border_color(c: Color) -> void:
	_border_top.color = c
	_border_bot.color = c

func _process(delta: float) -> void:
	if not _typing:
		return
	_char_timer += delta
	if _char_timer >= CHAR_DELAY:
		_char_timer = 0.0
		_displayed_chars = mini(_displayed_chars + 1, _full_text.length())
		_text_label.text = _full_text.substr(0, _displayed_chars)
		if _displayed_chars >= _full_text.length():
			_typing = false
			_hint_label.visible = true
			_waiting_for_input = true

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey or event is InputEventMouseButton):
		return
	if not event.is_pressed():
		return

	if _typing:
		_displayed_chars = _full_text.length()
		_text_label.text = _full_text
		_typing = false
		_hint_label.visible = true
		_waiting_for_input = true
		get_viewport().set_input_as_handled()
		return

	if _waiting_for_input:
		_waiting_for_input = false
		_current_line += 1
		_show_line(_current_line)
		get_viewport().set_input_as_handled()

func _finish() -> void:
	_hint_label.visible = false
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func():
		if auto_unpause:
			get_tree().paused = false
		dialogue_finished.emit()
		queue_free()
	)
