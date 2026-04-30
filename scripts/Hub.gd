extends Node2D

# ── Asset paths (swap these to upgrade visuals later) ────────────────────────
const TILE_PATH    := "res://assets/isometric tileset/isometric tileset/separated images/tile_%03d.png"
const TILES_HUB    := [34, 35, 36]       # green tiles — main hub floor
const TILES_PATH   := [20, 21, 22, 23]   # mossy tiles — exit path
const TILES_EDGE   := [60, 61]           # rocky border
# swap NPC_SPRITE for a real character sprite later
const NPC_SPRITE   := "res://assets/props_decoracao/props_decoracao_001.png"
# swap EXIT_SPRITE for a gate / portal sprite later
const EXIT_SPRITE  := "res://assets/props_decoracao/props_decoracao_005.png"
# ─────────────────────────────────────────────────────────────────────────────

const PLAYER_SCENE := preload("res://scenes/Player.tscn")

const TILE_W    := 32
const TILE_H    := 32
const MAP_COLS  := 20
const MAP_ROWS  := 14

# Exit path corridor (right side of map)
const PATH_COL_START := 13
const PATH_ROW_MIN   := 5
const PATH_ROW_MAX   := 8

# Grid coords for key positions
const PLAYER_COL := 3;  const PLAYER_ROW := 7
const NPC_COL    := 8;  const NPC_ROW    := 6
const EXIT_COL   := 19; const EXIT_ROW   := 6

const UPGRADE_DEFS: Array[Dictionary] = [
	{"attr": "attack_damage", "name": "Força",      "bonus": "+5 Ataque",     "cost": 15},
	{"attr": "max_health",    "name": "Vitalidade",  "bonus": "+20 Vida",      "cost": 12},
	{"attr": "dash_cd",       "name": "Agilidade",   "bonus": "-0.1s Dash CD", "cost": 20},
]

var _player: CharacterBody2D
var _npc_prompt: Label
var _player_near_npc  := false
var _player_near_exit := false
var _shop_open        := false
var _frag_label: Label

func _ready() -> void:
	_build_map()
	_spawn_player()
	_spawn_npc()
	_spawn_exit()
	_build_hud()
	ProgressionManager.fragments_changed.connect(func(_n): _refresh_hud())
	_refresh_hud()

# ── Map ───────────────────────────────────────────────────────────────────────

func _iso(col: int, row: int) -> Vector2:
	return Vector2((col - row) * TILE_W / 2.0, (col + row) * TILE_H / 4.0)

func _pick(seed_val: int, count: int) -> int:
	return abs(seed_val * 1013904223 + 1664525) % count

func _build_map() -> void:
	for row in MAP_ROWS:
		for col in MAP_COLS:
			var border := col == 0 or col == MAP_COLS - 1 or row == 0 or row == MAP_ROWS - 1
			var on_path := col >= PATH_COL_START and row >= PATH_ROW_MIN and row <= PATH_ROW_MAX
			var idx: int
			if border:
				idx = TILES_EDGE[_pick(col + row * MAP_COLS, TILES_EDGE.size())]
			elif on_path:
				idx = TILES_PATH[_pick(col + row * MAP_COLS, TILES_PATH.size())]
			else:
				idx = TILES_HUB[_pick(col + row * MAP_COLS, TILES_HUB.size())]
			var spr := Sprite2D.new()
			spr.texture = load(TILE_PATH % idx)
			spr.position = _iso(col, row)
			spr.z_index = -10
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(spr)

# ── Player ────────────────────────────────────────────────────────────────────

func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate()
	_player.position = _iso(PLAYER_COL, PLAYER_ROW)
	_player.add_to_group("player")
	add_child(_player)
	_player.died.connect(func():
		TransitionScreen.fade_to("res://scenes/MainMenu.tscn")
	)

# ── NPC ───────────────────────────────────────────────────────────────────────

func _spawn_npc() -> void:
	var pos := _iso(NPC_COL, NPC_ROW)

	var spr := Sprite2D.new()
	spr.texture = load(NPC_SPRITE)
	spr.position = pos
	spr.z_index = 1
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(spr)

	var name_lbl := Label.new()
	name_lbl.text = "Mercador"
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	name_lbl.position = pos + Vector2(-28, -42)
	name_lbl.z_index = 5
	add_child(name_lbl)

	_npc_prompt = Label.new()
	_npc_prompt.text = "[F] Loja"
	_npc_prompt.add_theme_font_size_override("font_size", 10)
	_npc_prompt.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	_npc_prompt.position = pos + Vector2(-20, -56)
	_npc_prompt.z_index = 6
	_npc_prompt.hide()
	add_child(_npc_prompt)

	var area := Area2D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 44.0
	shape.shape = circle
	area.add_child(shape)
	area.body_entered.connect(func(b):
		if b == _player:
			_player_near_npc = true
			_npc_prompt.show()
	)
	area.body_exited.connect(func(b):
		if b == _player:
			_player_near_npc = false
			_npc_prompt.hide()
	)
	add_child(area)

# ── Exit zone ─────────────────────────────────────────────────────────────────

func _spawn_exit() -> void:
	var pos := _iso(EXIT_COL, EXIT_ROW)

	var spr := Sprite2D.new()
	spr.texture = load(EXIT_SPRITE)
	spr.position = pos
	spr.z_index = 2
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(spr)

	var lbl := Label.new()
	lbl.text = "Floresta"
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.5))
	lbl.position = pos + Vector2(-22, -42)
	lbl.z_index = 5
	add_child(lbl)

	var area := Area2D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(64.0, 52.0)
	shape.shape = rect
	area.add_child(shape)
	area.body_entered.connect(func(b):
		if b == _player and not _player_near_exit:
			_player_near_exit = true
			_show_forest_prompt()
	)
	area.body_exited.connect(func(b):
		if b == _player:
			_player_near_exit = false
	)
	add_child(area)

# ── HUD ───────────────────────────────────────────────────────────────────────

func _build_hud() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 3
	add_child(cl)
	_frag_label = Label.new()
	_frag_label.add_theme_font_size_override("font_size", 20)
	_frag_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.25))
	_frag_label.position = Vector2(16, 16)
	cl.add_child(_frag_label)

func _refresh_hud() -> void:
	if _frag_label:
		_frag_label.text = "✦ %d Fragmentos" % ProgressionManager.get_fragments()

# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F and _player_near_npc and not _shop_open:
			_open_shop()

# ── Forest prompt ─────────────────────────────────────────────────────────────

func _show_forest_prompt() -> void:
	get_tree().paused = true
	var cl := _make_overlay(20, "ForestPrompt")
	var vbox := _make_vbox(cl, 360)

	_make_label(vbox, "Entrar na Floresta?", 32, Color(0.9, 0.8, 0.3))
	_make_label(vbox, "Inimigos aguardam além das árvores.", 15, Color(0.7, 0.65, 0.65))

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	hbox.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(hbox)

	var yes := _make_button("⚔  Entrar", 20, 140)
	yes.pressed.connect(func():
		get_tree().paused = false
		TransitionScreen.fade_to("res://scenes/World.tscn")
	)
	hbox.add_child(yes)

	var no := _make_button("Voltar", 20, 140)
	no.pressed.connect(func():
		get_tree().paused = false
		_player_near_exit = false
		cl.queue_free()
	)
	hbox.add_child(no)

# ── Shop ──────────────────────────────────────────────────────────────────────

func _open_shop() -> void:
	_shop_open = true
	get_tree().paused = true
	var cl := _make_overlay(20, "ShopPanel")
	var vbox := _make_vbox(cl, 460)

	_make_label(vbox, "Mercador", 36, Color(0.9, 0.75, 0.2))
	_make_label(vbox, "\"Fragmentos de alma... trocá-los por força.\"", 13, Color(0.6, 0.55, 0.65))

	var frag_lbl := _make_label(vbox, "", 20, Color(0.85, 0.75, 0.25))

	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(400, 8)
	vbox.add_child(sep)

	var btns: Array[Button] = []
	for def in UPGRADE_DEFS:
		var btn := _make_button("", 18, 400)
		btn.pressed.connect(func():
			ProgressionManager.buy_hub_upgrade(def["attr"])
			_refresh_shop(btns, frag_lbl)
		)
		vbox.add_child(btn)
		btns.append(btn)

	var sep2 := HSeparator.new()
	sep2.custom_minimum_size = Vector2(400, 8)
	vbox.add_child(sep2)

	var close := _make_button("Fechar", 18, 200)
	close.pressed.connect(func():
		_shop_open = false
		get_tree().paused = false
		cl.queue_free()
	)
	vbox.add_child(close)

	_refresh_shop(btns, frag_lbl)

func _refresh_shop(btns: Array[Button], frag_lbl: Label) -> void:
	frag_lbl.text = "✦  %d Fragmentos de Alma" % ProgressionManager.get_fragments()
	for i in btns.size():
		var def: Dictionary = UPGRADE_DEFS[i]
		var lvl  := ProgressionManager.get_hub_upgrade_count(def["attr"])
		var cost := def["cost"] as int
		btns[i].text     = "%s  Lv.%d/5  —  %s  (✦ %d)" % [def["name"], lvl, def["bonus"], cost]
		btns[i].disabled = lvl >= 5 or ProgressionManager.get_fragments() < cost

# ── UI helpers ────────────────────────────────────────────────────────────────

func _make_overlay(layer_val: int, node_name: String) -> CanvasLayer:
	var cl := CanvasLayer.new()
	cl.layer = layer_val
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	cl.name = node_name
	add_child(cl)
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.78)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	cl.add_child(bg)
	return cl

func _make_vbox(cl: CanvasLayer, min_width: float) -> VBoxContainer:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	cl.add_child(root)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(min_width, 0)
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(vbox)
	return vbox

func _make_label(parent: Control, text_val: String, font_sz: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text_val
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl

func _make_button(text_val: String, font_sz: int, min_width: float) -> Button:
	var btn := Button.new()
	btn.text = text_val
	btn.custom_minimum_size = Vector2(min_width, 52)
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	return btn
