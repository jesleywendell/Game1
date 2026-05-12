extends CanvasLayer

signal finished

const LINES: Array[String] = [
	"Ele não estava errado.",
	"Kaerlid é podre. Covarde. Vazio.",
	"Eu quebrei meu juramento.",
	"Nada disso mudou.",
	"Mas eu ainda estou aqui.",
	"Isso terá que ser suficiente.",
]

const FADE_IN  := 0.55
const HOLD     := 1.80
const FADE_OUT := 0.45

var _index := 0
var _label: Label

func _ready() -> void:
	layer = 19
	process_mode = Node.PROCESS_MODE_ALWAYS

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	_label.add_theme_constant_override("shadow_offset_x", 3)
	_label.add_theme_constant_override("shadow_offset_y", 3)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(820.0, 0.0)
	_label.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_label)

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(overlay, "color:a", 0.60, 0.9)
	tw.tween_interval(0.3)
	tw.tween_callback(_show_next)

func _show_next() -> void:
	if _index >= LINES.size():
		_end()
		return

	_label.text = LINES[_index]
	_label.modulate.a = 0.0

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_label, "modulate:a", 1.0, FADE_IN)
	tw.tween_interval(HOLD)
	tw.tween_property(_label, "modulate:a", 0.0, FADE_OUT)
	tw.tween_callback(func():
		_index += 1
		_show_next()
	)

func _end() -> void:
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(0.4)
	tw.tween_callback(func():
		finished.emit()
		queue_free()
	)
