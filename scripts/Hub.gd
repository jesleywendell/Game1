extends Node2D

const UPGRADE_DEFS: Array[Dictionary] = [
	{"attr": "attack_damage", "name": "Força",     "bonus": "+5 Ataque",    "cost": 15},
	{"attr": "max_health",    "name": "Vitalidade", "bonus": "+20 Vida",     "cost": 12},
	{"attr": "dash_cd",       "name": "Agilidade",  "bonus": "-0.1s Dash CD",  "cost": 20},
]

var _frag_label: Label
var _upgrade_buttons: Array[Button] = []

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.03, 0.07, 1.0)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	add_child(bg)

	var vp := get_viewport().get_visible_rect().size
	_build_background(vp)

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.45)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	add_child(overlay)

	var cl := CanvasLayer.new()
	cl.layer = 5
	add_child(cl)

	var root_ctrl := Control.new()
	root_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(root_ctrl)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(480, 0)
	root_ctrl.add_child(vbox)

	var title := Label.new()
	title.text = "HUB CENTRAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2, 1.0))
	vbox.add_child(title)

	var npc_lbl := Label.new()
	npc_lbl.text = "\"Fragmentos de alma… trocá-los por força.\""
	npc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	npc_lbl.add_theme_font_size_override("font_size", 15)
	npc_lbl.add_theme_color_override("font_color", Color(0.6, 0.55, 0.65, 1.0))
	vbox.add_child(npc_lbl)

	_frag_label = Label.new()
	_frag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frag_label.add_theme_font_size_override("font_size", 24)
	_frag_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.25, 1.0))
	vbox.add_child(_frag_label)

	var sep1 := HSeparator.new()
	sep1.custom_minimum_size = Vector2(400, 10)
	vbox.add_child(sep1)

	for def in UPGRADE_DEFS:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(400, 58)
		btn.add_theme_font_size_override("font_size", 19)
		btn.pressed.connect(_on_upgrade.bind(def["attr"]))
		vbox.add_child(btn)
		_upgrade_buttons.append(btn)

	var sep2 := HSeparator.new()
	sep2.custom_minimum_size = Vector2(400, 10)
	vbox.add_child(sep2)

	var enter_btn := Button.new()
	enter_btn.text = "⚔  Entrar na Floresta"
	enter_btn.custom_minimum_size = Vector2(300, 58)
	enter_btn.add_theme_font_size_override("font_size", 24)
	enter_btn.pressed.connect(func():
		TransitionScreen.fade_to("res://scenes/World.tscn")
	)
	vbox.add_child(enter_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Menu Principal"
	menu_btn.custom_minimum_size = Vector2(300, 44)
	menu_btn.add_theme_font_size_override("font_size", 18)
	menu_btn.pressed.connect(func():
		TransitionScreen.fade_to("res://scenes/MainMenu.tscn")
	)
	vbox.add_child(menu_btn)

	ProgressionManager.fragments_changed.connect(func(_n): _refresh())
	_refresh()

func _refresh() -> void:
	var frags := ProgressionManager.get_fragments()
	_frag_label.text = "✦  %d  Fragmentos de Alma" % frags
	for i in _upgrade_buttons.size():
		var def: Dictionary = UPGRADE_DEFS[i]
		var level := ProgressionManager.get_hub_upgrade_count(def["attr"])
		var cost: int  = def["cost"]
		var maxed := level >= 5
		_upgrade_buttons[i].text = "%s  Lv.%d/5  —  %s  (✦ %d)" % [
			def["name"], level, def["bonus"], cost
		]
		_upgrade_buttons[i].disabled = maxed or frags < cost

func _add_sprite(path: String, pos: Vector2, scale_v: Vector2 = Vector2.ONE, z: int = 0) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = load(path)
	spr.position = pos
	spr.scale = scale_v
	spr.z_index = z
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(spr)
	return spr

func _build_background(vp: Vector2) -> void:
	# sky gradient — fills the upper half
	var sky := ColorRect.new()
	sky.color = Color(0.06, 0.04, 0.10, 1.0)
	sky.position = Vector2.ZERO
	sky.size = Vector2(vp.x, vp.y * 0.62)
	sky.z_index = -10
	add_child(sky)

	# ground tiles
	var ground_tex: Texture2D = load("res://assets/tiles_chao/tiles_chao_001.png")
	if ground_tex:
		var ground := Sprite2D.new()
		ground.texture = ground_tex
		ground.position = Vector2(vp.x * 0.5, vp.y * 0.62)
		ground.scale = Vector2(vp.x / float(ground_tex.get_width()), 5.0)
		ground.z_index = -5
		ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(ground)

	var ground2_tex: Texture2D = load("res://assets/tiles_chao/tiles_chao_008.png")
	if ground2_tex:
		var ground2 := Sprite2D.new()
		ground2.texture = ground2_tex
		ground2.position = Vector2(vp.x * 0.5, vp.y * 0.95)
		ground2.scale = Vector2(vp.x / float(ground2_tex.get_width()), 2.5)
		ground2.z_index = -4
		ground2.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(ground2)

	# distant silhouettes — deep background
	_add_sprite("res://assets/edificacoes_grandes/edificacoes_grandes_005.png", Vector2(vp.x * 0.50, vp.y * 0.38), Vector2(1.2, 1.2), -4)
	_add_sprite("res://assets/edificacoes_grandes/edificacoes_grandes_003.png", Vector2(vp.x * 0.20, vp.y * 0.42), Vector2(1.0, 1.0), -4)
	_add_sprite("res://assets/edificacoes_grandes/edificacoes_grandes_007.png", Vector2(vp.x * 0.80, vp.y * 0.42), Vector2(1.0, 1.0), -4)

	# large buildings — background layer (horizon)
	_add_sprite("res://assets/edificacoes_grandes/edificacoes_grandes_001.png", Vector2(vp.x * 0.08, vp.y * 0.54), Vector2(1.8, 1.8), -1)
	_add_sprite("res://assets/edificacoes_grandes/edificacoes_grandes_010.png", Vector2(vp.x * 0.90, vp.y * 0.54), Vector2(1.8, 1.8), -1)

	# small buildings — mid layer
	_add_sprite("res://assets/edificacoes_pequenas/edificacoes_pequenas_001.png", Vector2(vp.x * 0.26, vp.y * 0.64), Vector2(1.5, 1.5), 0)
	_add_sprite("res://assets/edificacoes_pequenas/edificacoes_pequenas_002.png", Vector2(vp.x * 0.74, vp.y * 0.64), Vector2(1.5, 1.5), 0)
	_add_sprite("res://assets/edificacoes_pequenas/edificacoes_pequenas_003.png", Vector2(vp.x * 0.50, vp.y * 0.66), Vector2(1.3, 1.3), 0)

	# vegetation — foreground edges
	_add_sprite("res://assets/vegetacao_estruturas/vegetacao_estruturas_001.png", Vector2(vp.x * 0.01, vp.y * 0.72), Vector2(1.8, 1.8), 2)
	_add_sprite("res://assets/vegetacao_estruturas/vegetacao_estruturas_008.png", Vector2(vp.x * 0.97, vp.y * 0.72), Vector2(1.8, 1.8), 2)
	_add_sprite("res://assets/vegetacao_estruturas/vegetacao_estruturas_015.png", Vector2(vp.x * 0.16, vp.y * 0.78), Vector2(1.4, 1.4), 3)
	_add_sprite("res://assets/vegetacao_estruturas/vegetacao_estruturas_002.png", Vector2(vp.x * 0.84, vp.y * 0.78), Vector2(1.4, 1.4), 3)

	# tombstones / fences
	_add_sprite("res://assets/tombulos_cercas/tombulos_cercas_001.png", Vector2(vp.x * 0.36, vp.y * 0.74), Vector2(1.6, 1.6), 1)
	_add_sprite("res://assets/tombulos_cercas/tombulos_cercas_005.png", Vector2(vp.x * 0.64, vp.y * 0.74), Vector2(1.6, 1.6), 1)

	# props — ground level
	_add_sprite("res://assets/props_decoracao/props_decoracao_006.png", Vector2(vp.x * 0.20, vp.y * 0.82), Vector2(1.3, 1.3), 4)
	_add_sprite("res://assets/props_decoracao/props_decoracao_012.png", Vector2(vp.x * 0.78, vp.y * 0.82), Vector2(1.3, 1.3), 4)

func _on_upgrade(attribute: String) -> void:
	ProgressionManager.buy_hub_upgrade(attribute)
