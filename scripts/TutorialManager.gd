extends Node

# Passos: [tecla, descrição, Callable de condição]
const STEPS: Array[Dictionary] = [
	{"key": "WASD",  "desc": "Mova o personagem"},
	{"key": "ESPAÇO","desc": "Use o dash"},
	{"key": "Mouse", "desc": "Ataque com o botão esquerdo"},
	{"key": "Q",     "desc": "Use a habilidade em área"},
	{"key": "E",     "desc": "Dispare o projétil"},
]

var _player: CharacterBody2D
var _skill_manager: Node

var _step       := 0
var _fading     := false
var _cl: CanvasLayer
var _panel: PanelContainer
var _key_lbl: Label
var _desc_lbl: Label
var _dots: HBoxContainer

func init(player: CharacterBody2D) -> void:
	_player = player
	_skill_manager = player.get_node("SkillManager")
	_build_ui()
	_show_step(0)

func _build_ui() -> void:
	var vp := get_viewport().get_visible_rect().size

	_cl = CanvasLayer.new()
	_cl.layer = 4
	add_child(_cl)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(340, 0)
	_panel.position = Vector2((vp.x - 340) * 0.5, vp.y - 130)

	var style := StyleBoxFlat.new()
	style.bg_color          = Color(0.05, 0.04, 0.08, 0.82)
	style.corner_radius_top_left     = 10
	style.corner_radius_top_right    = 10
	style.corner_radius_bottom_left  = 10
	style.corner_radius_bottom_right = 10
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_color = Color(0.55, 0.45, 0.75, 0.6)
	_panel.add_theme_stylebox_override("panel", style)
	_cl.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(vbox)

	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	vbox.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	margin.add_child(inner)

	_key_lbl = Label.new()
	_key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_key_lbl.add_theme_font_size_override("font_size", 22)
	_key_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.25))
	inner.add_child(_key_lbl)

	_desc_lbl = Label.new()
	_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_lbl.add_theme_font_size_override("font_size", 15)
	_desc_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	inner.add_child(_desc_lbl)

	_dots = HBoxContainer.new()
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots.add_theme_constant_override("separation", 6)
	inner.add_child(_dots)
	for i in STEPS.size():
		var dot := Label.new()
		dot.text = "●"
		dot.add_theme_font_size_override("font_size", 10)
		_dots.add_child(dot)

func _show_step(index: int) -> void:
	if index >= STEPS.size():
		_finish()
		return
	_step = index
	var s: Dictionary = STEPS[index]
	_key_lbl.text  = "[ %s ]" % s["key"]
	_desc_lbl.text = s["desc"]
	_update_dots()
	_panel.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_panel, "modulate:a", 1.0, 0.25)

func _update_dots() -> void:
	for i in _dots.get_child_count():
		var dot := _dots.get_child(i) as Label
		if i < _step:
			dot.add_theme_color_override("font_color", Color(0.55, 0.45, 0.75, 0.9))
		elif i == _step:
			dot.add_theme_color_override("font_color", Color(0.95, 0.82, 0.25))
		else:
			dot.add_theme_color_override("font_color", Color(0.35, 0.32, 0.38, 0.5))

func _process(_delta: float) -> void:
	if _fading or _player == null:
		return
	if _check_step(_step):
		_advance()

func _check_step(index: int) -> bool:
	match index:
		0: return _player.velocity.length() > 10.0
		1: return _player.is_dashing
		2: return _player.is_attacking
		3: return _skill_manager.skill_q_active_timer > 0.0
		4: return _skill_manager.cooldown_e_timer > 0.0
	return false

func _advance() -> void:
	_fading = true
	var t := create_tween()
	t.tween_property(_panel, "modulate:a", 0.0, 0.2)
	t.tween_callback(func():
		_fading = false
		_show_step(_step + 1)
	)

func _finish() -> void:
	var t := create_tween()
	t.tween_property(_panel, "modulate:a", 0.0, 0.4)
	t.tween_callback(queue_free)
