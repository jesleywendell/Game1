extends CanvasLayer

const BG   := "res://assets/pause/background/Paused2.png"
const CONT := "res://assets/pause/botoes/continue.png"
const MENU := "res://assets/pause/return_menu_principal.png"

var _root: Control

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if visible:
		_resume()
	elif not get_tree().paused:
		_open()
	get_viewport().set_input_as_handled()

func _open() -> void:
	get_tree().paused = true
	_root.modulate.a = 0.0
	show()
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.18)

func _resume() -> void:
	var t := create_tween()
	t.tween_property(_root, "modulate:a", 0.0, 0.12)
	t.tween_callback(func():
		hide()
		_root.modulate.a = 1.0
		get_tree().paused = false
	)

func _build() -> void:
	var vp := get_viewport().get_visible_rect().size

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var ov := ColorRect.new()
	ov.color = Color(0.0, 0.0, 0.0, 0.68)
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	ov.process_mode = Node.PROCESS_MODE_ALWAYS
	_root.add_child(ov)

	var bg_img  := Image.load_from_file(BG)
	var btn_img := Image.load_from_file(CONT)

	var pw  := vp.x * 0.48
	var ph  := pw * (float(bg_img.get_height()) / float(bg_img.get_width()))
	var px  := (vp.x * 0.5) - (pw * 0.5)
	var py  := (vp.y * 0.5) - (ph * 0.5)

	var bg := TextureRect.new()
	bg.texture = ImageTexture.create_from_image(bg_img)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_position(Vector2(px, py))
	bg.set_size(Vector2(pw, ph))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)

	var bw := pw * 0.46
	var bh := bw * (float(btn_img.get_height()) / float(btn_img.get_width()))
	var bx := px + (pw - bw) * 0.5 + pw * 0.06
	var gap := bh * 0.20
	var total_h := bh * 2.0 + gap
	var by0 := py + ph * 0.38 + (ph * 0.62 - total_h) * 0.5

	_btn(CONT, bx, by0,            bw, bh, _resume)
	_btn(MENU, bx, by0 + bh + gap, bw, bh, _go_main)

func _btn(path: String, x: float, y: float, w: float, h: float, cb: Callable) -> void:
	var btn := TextureButton.new()
	btn.texture_normal = ImageTexture.create_from_image(Image.load_from_file(path))
	btn.stretch_mode = TextureButton.STRETCH_SCALE
	btn.ignore_texture_size = true
	btn.set_position(Vector2(x, y))
	btn.set_size(Vector2(w, h))
	btn.pivot_offset = Vector2(w, h) * 0.5
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pressed.connect(cb)
	btn.mouse_entered.connect(func():
		AudioManager.play_btn_hover()
		create_tween().tween_property(btn, "modulate", Color(1.3, 1.15, 0.85), 0.10)
	)
	btn.mouse_exited.connect(func():
		create_tween().tween_property(btn, "modulate", Color(1.0, 1.0, 1.0), 0.12)
	)
	btn.button_down.connect(func():
		AudioManager.play_btn_click()
		create_tween().tween_property(btn, "scale", Vector2(0.96, 0.96), 0.06).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func():
		create_tween().tween_property(btn, "scale", Vector2(1.0, 1.0), 0.10).set_ease(Tween.EASE_OUT)
	)
	_root.add_child(btn)

func _go_main() -> void:
	hide()
	get_tree().paused = false
	TransitionScreen.fade_to("res://scenes/MainMenu.tscn")
