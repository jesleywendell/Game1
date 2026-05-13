extends Node2D

const IMG_CREDITS := "res://assets/creditos/credits/Tela_Creditos_2.png"
const IMG_BTN     := "res://assets/creditos/botao/botao_tela_creditos.png"

func _ready() -> void:
	var vp := get_viewport().get_visible_rect().size

	var cl := CanvasLayer.new()
	cl.layer = 1
	add_child(cl)

	# ── Background ────────────────────────────────────────────────────────────
	var bg_tex := load(IMG_CREDITS) as Texture2D
	var bg := TextureRect.new()
	bg.texture = bg_tex
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(bg)

	# ── Back button — centered within the credits image frame ─────────────────
	var btn_tex  := load(IMG_BTN) as Texture2D

	# Scale the button proportionally: ~22 % of viewport width
	var btn_w := vp.x * 0.22
	var btn_h := btn_w * (float(btn_tex.get_height()) / float(btn_tex.get_width()))

	# Horizontal center matches the credits image (which fills the viewport)
	var btn_x := (vp.x - btn_w) * 0.5
	# Vertical: near the bottom of the frame — adjust BTN_Y_RATIO to taste
	const BTN_Y_RATIO := 0.88
	var btn_y := vp.y * BTN_Y_RATIO - btn_h * 0.5

	var btn := TextureButton.new()
	btn.texture_normal = btn_tex
	btn.stretch_mode = TextureButton.STRETCH_SCALE
	btn.ignore_texture_size = true
	btn.set_position(Vector2(btn_x, btn_y))
	btn.set_size(Vector2(btn_w, btn_h))
	btn.pivot_offset = Vector2(btn_w, btn_h) * 0.5

	btn.mouse_entered.connect(func():
		create_tween().tween_property(btn, "modulate", Color(1.3, 1.15, 0.85), 0.10)
	)
	btn.mouse_exited.connect(func():
		create_tween().tween_property(btn, "modulate", Color(1.0, 1.0, 1.0), 0.12)
	)
	btn.button_down.connect(func():
		create_tween().tween_property(btn, "scale", Vector2(0.96, 0.96), 0.06).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func():
		create_tween().tween_property(btn, "scale", Vector2(1.0, 1.0), 0.10).set_ease(Tween.EASE_OUT)
	)
	btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)

	cl.add_child(btn)
