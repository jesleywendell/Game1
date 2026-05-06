extends Node2D

const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const PAUSE_MENU   := preload("res://scenes/PauseMenu.tscn")

const TILE_W    := 32
const TILE_H    := 32

const HUB_COLS    := 30
const HUB_ROWS    := 20
const PLAYER_COL  := 4;   const PLAYER_ROW := 10
const EXIT_COL    := 24;  const EXIT_ROW   := 10

const TILE_PATH   := "res://assets/isometric tileset/isometric tileset/separated images/tile_%03d.png"
const TILES_SOIL  := [12, 13, 14]
const TILES_PATH  := [34, 35, 36]
const FOREST_ROOT := "res://assets/forest/"
const UNDEAD_ROOT := "res://assets/Free-Undead-Tileset-Top-Down-Pixel-Art/PNG/Objects_separately/"

var _player: CharacterBody2D
var _player_near_exit := false
var _frag_label: Label
var _background_rect: ColorRect
var _time_accum: float = 0.0
var _floresta_lbl: Label
var _light_texture: Texture2D
var _path_set: Dictionary = {}
var _occupied: Dictionary = {}
var _hole_light: PointLight2D

func _iso(col: int, row: int) -> Vector2:
	return Vector2((col - row) * TILE_W / 2.0, (col + row) * TILE_H / 4.0)

func _is_corner_cut(col: int, row: int) -> bool:
	return (col + row < 5 or
		(29 - col) + row < 5 or
		(29 - col) + (19 - row) < 5 or
		col + (19 - row) < 6)

func _ready() -> void:
	add_child(PAUSE_MENU.instantiate())
	_setup_atmosphere()
	var cm := CanvasModulate.new()
	cm.color = Color(0.22, 0.24, 0.28, 1.0)
	add_child(cm)
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for y in range(128):
		for x in range(128):
			var d: float = Vector2(float(x) - 64.0, float(y) - 64.0).length() / 64.0
			var a: float = 0.0
			if d < 1.0:
				var t: float = 1.0 - d
				t = t * t * (3.0 - 2.0 * t)
				a = t * t
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_light_texture = ImageTexture.create_from_image(img)
	_build_hub_map()
	_build_border_colliders()
	_spawn_player()
	_spawn_exit()
	_setup_foreground()
	_build_hud()
	ProgressionManager.fragments_changed.connect(func(_n): _refresh_hud())
	_refresh_hud()

func _process(delta: float) -> void:
	_time_accum += delta
	if _background_rect and _background_rect.material:
		_background_rect.material.set_shader_parameter("time", _time_accum)
	if _player and _floresta_lbl:
		_floresta_lbl.visible = _player_near_exit
	if _hole_light:
		_hole_light.energy = 0.5 + sin(_time_accum * 1.5) * 0.3
	if _player:
		_player.z_index = int(_player.position.y / 8.0)
		var cam := _player.get_node("Camera2D") as Camera2D
		if cam:
			cam.offset = Vector2(sin(_time_accum * 0.3) * 3.0, cos(_time_accum * 0.4) * 3.0)

func _setup_atmosphere() -> void:
	var void_layer := CanvasLayer.new()
	void_layer.layer = -10
	add_child(void_layer)
	_background_rect = ColorRect.new()
	_background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background_rect.color = Color(0.05, 0.0, 0.0)
	var bg_shader := Shader.new()
	bg_shader.code = """
shader_type canvas_item;
uniform float time;
vec2 hash2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(dot(hash2(i), f), dot(hash2(i + vec2(1, 0)), f - vec2(1, 0)), f.x),
		   mix(dot(hash2(i + vec2(0, 1)), f - vec2(0, 1)), dot(hash2(i + vec2(1, 1)), f - vec2(1, 1)), f.x), f.y);
}
void fragment() {
	vec2 uv = UV * 3.0;
	float n1 = noise(uv + time * 0.02);
	float n2 = noise(uv * 2.5 - time * 0.04);
	float mist = n1 * 0.5 + n2 * 0.5;
	vec3 dark = vec3(0.03, 0.0, 0.02);
	vec3 crimson = vec3(0.25, 0.05, 0.05);
	vec3 ember = vec3(0.6, 0.1, 0.0);
	COLOR = vec4(mix(mix(dark, crimson, mist), ember, smoothstep(0.7, 1.0, mist)), 1.0);
}
"""
	var bg_mat := ShaderMaterial.new()
	bg_mat.shader = bg_shader
	_background_rect.material = bg_mat
	void_layer.add_child(_background_rect)
	var cl := CanvasLayer.new()
	cl.layer = 1
	add_child(cl)
	var ambient := ColorRect.new()
	ambient.color = Color(0.04, 0.02, 0.06, 0.08)
	ambient.anchors_preset = Control.PRESET_FULL_RECT
	cl.add_child(ambient)
	var vignette := ColorRect.new()
	vignette.anchors_preset = Control.PRESET_FULL_RECT
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv) * 1.8;
	float v = smoothstep(0.25, 1.0, dist);
	COLOR = vec4(0.0, 0.0, 0.0, v * 0.48);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	vignette.material = mat
	cl.add_child(vignette)
	var embers := CPUParticles2D.new()
	embers.emitting = true
	embers.amount = 45
	embers.lifetime = 8.0
	embers.one_shot = false
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(500.0, 200.0)
	embers.direction = Vector2(0.0, -1.0)
	embers.spread = 40.0
	embers.gravity = Vector2(0.0, -6.0)
	embers.initial_velocity_min = 3.0
	embers.initial_velocity_max = 12.0
	embers.scale_amount_min = 3.0
	embers.scale_amount_max = 8.0
	embers.color = Color(0.9, 0.35, 0.08, 0.32)
	embers.z_index = 10
	add_child(embers)
	var fog := CPUParticles2D.new()
	fog.emitting = true
	fog.amount = 80
	fog.lifetime = 12.0
	fog.one_shot = false
	fog.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fog.emission_rect_extents = Vector2(600.0, 170.0)
	fog.direction = Vector2(-0.15, -0.05)
	fog.spread = 15.0
	fog.gravity = Vector2(0.0, 0.0)
	fog.initial_velocity_min = 3.0
	fog.initial_velocity_max = 8.0
	fog.scale_amount_min = 20.0
	fog.scale_amount_max = 50.0
	fog.color = Color(0.15, 0.04, 0.04, 0.12)
	fog.z_index = -8
	add_child(fog)

func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate()
	_player.position = _iso(PLAYER_COL, PLAYER_ROW)
	_player.add_to_group("player")
	_player.get_node("Camera2D").position_smoothing_enabled = true
	add_child(_player)
	var light := PointLight2D.new()
	light.color = Color(0.55, 0.7, 1.0)
	light.energy = 1.4
	light.texture = _light_texture
	light.texture_scale = 1.8
	light.z_index = 5
	light.range_z_min = -10
	light.range_z_max = 100
	light.position = Vector2(0, -24)
	_player.add_child(light)
	_player.died.connect(func():
		TransitionScreen.fade_to("res://scenes/MainMenu.tscn")
	)

func _build_hub_map() -> void:
	var waypoints: Array[Vector2i] = [
		Vector2i(4, 10), Vector2i(7, 8), Vector2i(11, 6),
		Vector2i(16, 7), Vector2i(20, 11), Vector2i(24, 10)
	]
	for wi in range(waypoints.size() - 1):
		var p1: Vector2i = waypoints[wi]
		var p2: Vector2i = waypoints[wi + 1]
		var steps := maxi(abs(p2.x - p1.x), abs(p2.y - p1.y))
		for s in range(steps + 1):
			var t := float(s) / float(steps)
			var c := roundi(lerp(float(p1.x), float(p2.x), t))
			var r := roundi(lerp(float(p1.y), float(p2.y), t))
			for dr in [-1, 0, 1]:
				_path_set[str(c) + "," + str(r + dr)] = true
	for row in HUB_ROWS:
		for col in HUB_COLS:
			if _is_corner_cut(col, row):
				continue
			var on_path := _path_set.has(str(col) + "," + str(row))
			var pool: Array = TILES_PATH if on_path else TILES_SOIL
			var idx: int = pool[abs(col * 31 + row * 97) % pool.size()]
			var spr := Sprite2D.new()
			spr.texture = load(TILE_PATH % idx)
			spr.position = _iso(col, row)
			spr.z_index = -10
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if not on_path:
				spr.modulate = Color(0.55, 0.60, 0.55)
			add_child(spr)
	var border_trees := ["Dead_tree_shadow1_1.png", "Dead_tree_shadow1_2.png", "Dead_tree_shadow1_3.png"]
	for row in HUB_ROWS:
		for col in HUB_COLS:
			if _is_corner_cut(col, row):
				continue
			if col < 3 or col >= 27 or row < 3 or row >= 17:
				if not _occupied.has(Vector2i(col, row)):
					var name: String = border_trees[abs(col * 41 + row * 79) % border_trees.size()]
					var spr := Sprite2D.new()
					spr.texture = load(FOREST_ROOT + name)
					spr.position = _iso(col, row) + Vector2(0, -8)
					spr.z_index = col + row
					spr.modulate = Color(0.5, 0.55, 0.5)
					spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
					add_child(spr)
					for dc in [-1, 0, 1]:
						for dr in [-1, 0, 1]:
							_occupied[Vector2i(col + dc, row + dr)] = true
	var scatter_pool := [
		"Bones_shadow1_1.png", "Bones_shadow1_3.png", "Bones_shadow1_5.png",
		"Bones_shadow1_8.png", "Bones_shadow1_11.png", "Bones_shadow1_14.png",
		"Rock_shadow1_1.png", "Rock_shadow1_2.png", "Rock_shadow1_3.png",
		"Rock_shadow1_4.png", "Rock_shadow1_5.png",
		"Plant_shadow1_1.png", "Plant_shadow1_2.png", "Plant_shadow1_3.png",
		"Plant_shadow1_4.png", "Plant_shadow1_5.png",
		"Broken_tree_shadow1_1.png", "Broken_tree_shadow1_2.png",
		"Broken_tree_shadow1_3.png", "Broken_tree_shadow1_4.png",
		"Broken_tree_shadow1_5.png", "Broken_tree_shadow1_6.png",
		"Broken_tree_shadow1_7.png",
		"Thorn_palnt_shadow2_1.png", "Thorn_palnt_shadow2_2.png",
		"Thorn_palnt_shadow2_3.png", "Thorn_palnt_shadow2_4.png",
		"Thorn_palnt_shadow2_5.png",
	]
	for row in HUB_ROWS:
		for col in HUB_COLS:
			if _is_corner_cut(col, row):
				continue
			if col < 3 or col >= 27 or row < 3 or row >= 17:
				continue
			if _path_set.has(str(col) + "," + str(row)):
				continue
			if _occupied.has(Vector2i(col, row)):
				continue
			if abs(col * 31 + row * 97) % 100 >= 30:
				continue
			var name: String = scatter_pool[abs(col * 53 + row * 71) % scatter_pool.size()]
			var spr := Sprite2D.new()
			spr.texture = load(FOREST_ROOT + name)
			spr.position = _iso(col, row) + Vector2(0, -6)
			spr.z_index = col + row
			spr.modulate = Color(0.6, 0.65, 0.6)
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(spr)
			for dc in [0, 1]:
				for dr in [0, 1]:
					_occupied[Vector2i(col + dc, row + dr)] = true
	var arm_offsets: Array[Vector2i] = [Vector2i(-2,-1), Vector2i(-1,-2), Vector2i(2,-1), Vector2i(-2,1), Vector2i(2,1)]
	for off in arm_offsets:
		var c: int = EXIT_COL + off.x
		var r: int = EXIT_ROW + off.y
		if c >= 0 and c < HUB_COLS and r >= 0 and r < HUB_ROWS:
			var idx: int = abs(c * 31 + r * 97) % 4 + 1
			var spr := Sprite2D.new()
			spr.texture = load(UNDEAD_ROOT + "Dead_arm_shadow1_%d.png" % idx)
			spr.position = _iso(c, r) + Vector2(0, -6)
			spr.z_index = c + r
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(spr)
	var crystal_offsets: Array[Vector2i] = [Vector2i(3,-2), Vector2i(-3,2), Vector2i(2,3)]
	for off in crystal_offsets:
		var c: int = EXIT_COL + off.x
		var r: int = EXIT_ROW + off.y
		if c >= 0 and c < HUB_COLS and r >= 0 and r < HUB_ROWS:
			var idx: int = abs(c * 41 + r * 67) % 4 + 1
			var spr := Sprite2D.new()
			spr.texture = load(UNDEAD_ROOT + "Crystal_shadow1_%d.png" % idx)
			spr.position = _iso(c, r) + Vector2(0, -8)
			spr.z_index = c + r
			spr.modulate = Color(0.5, 0.6, 1.0)
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(spr)

func _build_border_colliders() -> void:
	var verts: Array[Vector2] = [
		Vector2(80, 40),    # tile (5,0)   — top
		Vector2(384, 192),  # tile (24,0)  — top-right start
		Vector2(384, 272),  # tile (29,5)  — right top
		Vector2(240, 344),  # tile (29,14) — right bottom
		Vector2(80, 344),   # tile (24,19) — bottom-right
		Vector2(-208, 200), # tile (6,19)  — bottom-left
		Vector2(-208, 104), # tile (0,13)  — left bottom
		Vector2(-80, 40),   # tile (0,5)   — left top
	]
	for i in verts.size():
		var a: Vector2 = verts[i]
		var b: Vector2 = verts[(i + 1) % verts.size()]
		var mid: Vector2 = (a + b) / 2.0
		var seg_len: float = a.distance_to(b)
		var angle: float = (b - a).angle()
		var body := StaticBody2D.new()
		body.position = mid
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(seg_len, 12)
		shape.shape = rect
		shape.rotation = angle
		body.add_child(shape)
		add_child(body)

# ── Player ────────────────────────────────────────────────────────────────────

# ── Exit zone ─────────────────────────────────────────────────────────────────

func _spawn_exit() -> void:
	var pos := _iso(EXIT_COL, EXIT_ROW)

	var skull := Sprite2D.new()
	skull.texture = load(UNDEAD_ROOT + "Scull_door_shadow1.png")
	skull.position = pos
	skull.z_index = 2
	skull.modulate = Color(0.7, 0.5, 0.9)
	skull.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(skull)

	var smoke := CPUParticles2D.new()
	smoke.emitting = true
	smoke.amount = 15
	smoke.lifetime = 3.5
	smoke.one_shot = false
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = 20.0
	smoke.position = pos
	smoke.direction = Vector2(0.0, -1.0)
	smoke.spread = 25.0
	smoke.gravity = Vector2(0.0, -3.0)
	smoke.initial_velocity_min = 3.0
	smoke.initial_velocity_max = 8.0
	smoke.scale_amount_min = 8.0
	smoke.scale_amount_max = 14.0
	smoke.color = Color(0.08, 0.05, 0.15, 0.22)
	smoke.z_index = 3
	add_child(smoke)

	_hole_light = PointLight2D.new()
	_hole_light.color = Color(0.3, 0.4, 1.0)
	_hole_light.energy = 0.8
	_hole_light.texture = _light_texture
	_hole_light.texture_scale = 1.8
	_hole_light.z_index = 4
	_hole_light.range_z_min = -10
	_hole_light.range_z_max = 10
	_hole_light.position = pos
	add_child(_hole_light)

	_floresta_lbl = Label.new()
	_floresta_lbl.text = "O Buraco"
	_floresta_lbl.add_theme_font_size_override("font_size", 9)
	_floresta_lbl.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))
	_floresta_lbl.position = pos + Vector2(-28, -50)
	_floresta_lbl.z_index = 5
	_floresta_lbl.visible = false
	add_child(_floresta_lbl)

	var area := Area2D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(96.0, 64.0)
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
	var panel := Panel.new()
	panel.position = Vector2(16, 16)
	panel.size = Vector2(190, 56)
	cl.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(0, 0)
	vbox.size = Vector2(190, 56)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	_frag_label = Label.new()
	_frag_label.add_theme_font_size_override("font_size", 19)
	_frag_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	_frag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_frag_label)

func _refresh_hud() -> void:
	if _frag_label:
		_frag_label.text = "◆  %d  Fragmentos" % ProgressionManager.get_fragments()

# ── Foreground overlay ──────────────────────────────────────────────────────────

func _setup_foreground() -> void:
	var fg_layer := CanvasLayer.new()
	fg_layer.layer = 20
	add_child(fg_layer)

	var shadow := ColorRect.new()
	shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var grad_shader := Shader.new()
	grad_shader.code = """
shader_type canvas_item;
void fragment() {
	float gradient = smoothstep(0.65, 0.95, UV.y);
	COLOR = vec4(0.0, 0.0, 0.0, gradient * 0.42);
}
"""
	var grad_mat := ShaderMaterial.new()
	grad_mat.shader = grad_shader
	shadow.material = grad_mat
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fg_layer.add_child(shadow)

	var vp := get_viewport().get_visible_rect().size

	var bush_left := Sprite2D.new()
	bush_left.texture = load("res://assets/vegetacao_estruturas/vegetacao_estruturas_001.png")
	bush_left.position = Vector2(40, vp.y - 90)
	bush_left.z_index = 0
	bush_left.scale = Vector2(2.0, 2.0)
	bush_left.modulate = Color(0.05, 0.06, 0.05)
	bush_left.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fg_layer.add_child(bush_left)

	var bush_right := Sprite2D.new()
	bush_right.texture = load("res://assets/vegetacao_estruturas/vegetacao_estruturas_003.png")
	bush_right.position = Vector2(vp.x - 160, vp.y - 120)
	bush_right.z_index = 0
	bush_right.scale = Vector2(2.2, 2.2)
	bush_right.modulate = Color(0.05, 0.06, 0.05)
	bush_right.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fg_layer.add_child(bush_right)

	var top_left := Sprite2D.new()
	top_left.texture = load("res://assets/edificacoes_grandes/edificacoes_grandes_008.png")
	top_left.position = Vector2(-60, -60)
	top_left.z_index = 0
	top_left.scale = Vector2(3.5, 3.5)
	top_left.modulate = Color(0.04, 0.04, 0.06)
	top_left.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fg_layer.add_child(top_left)

	var top_right := Sprite2D.new()
	top_right.texture = load("res://assets/edificacoes_grandes/edificacoes_grandes_012.png")
	top_right.position = Vector2(vp.x - 200, -80)
	top_right.z_index = 0
	top_right.scale = Vector2(3.2, 3.2)
	top_right.modulate = Color(0.04, 0.04, 0.06)
	top_right.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fg_layer.add_child(top_right)

	var side_right := Sprite2D.new()
	side_right.texture = load("res://assets/edificacoes_pequenas/edificacoes_pequenas_008.png")
	side_right.position = Vector2(vp.x - 140, vp.y * 0.28)
	side_right.z_index = 0
	side_right.scale = Vector2(2.8, 2.8)
	side_right.modulate = Color(0.04, 0.04, 0.06)
	side_right.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fg_layer.add_child(side_right)

# ── Forest prompt ─────────────────────────────────────────────────────────────

func _show_forest_prompt() -> void:
	get_tree().paused = true
	var cl := _make_overlay(20, "ForestPrompt")
	var vbox := _make_vbox(cl, 360)

	var accent := Label.new()
	accent.text = "◆  ◆  ◆"
	accent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	accent.add_theme_font_size_override("font_size", 12)
	accent.add_theme_color_override("font_color", Color(0.3, 0.55, 1.0, 0.8))
	vbox.add_child(accent)

	_make_label(vbox, "Descer?", 32, Color(0.3, 0.65, 1.0))
	_make_label(vbox, "A escuridão chama.", 15, Color(0.6, 0.6, 0.75))

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	hbox.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(hbox)

	var yes := _make_button("⚔  Descer", 20, 140)
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

	var sep2 := Control.new()
	sep2.custom_minimum_size = Vector2(0, 8)
	sep2.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(sep2)

	var nj_btn := _make_button("Recome\u00e7ar Jornada", 18, 220)
	nj_btn.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	nj_btn.pressed.connect(func():
		ProgressionManager.reset_level()
		ProgressionManager.data.current_area = 1
		ProgressionManager.save()
		get_tree().paused = false
		TransitionScreen.fade_to("res://scenes/World.tscn")
	)
	vbox.add_child(nj_btn)

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
	btn.add_theme_color_override("font_color", Color(0.9, 0.82, 0.35))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.5))
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.15, 0.92)
	sb.border_color = Color(0.7, 0.5, 0.12, 0.7)
	sb.border_width_left   = 2
	sb.border_width_right  = 2
	sb.border_width_top    = 4
	sb.border_width_bottom = 2
	sb.corner_radius_top_left     = 2
	sb.corner_radius_top_right    = 2
	sb.corner_radius_bottom_left  = 2
	sb.corner_radius_bottom_right = 2
	btn.add_theme_stylebox_override("normal", sb)
	var hover_sb := StyleBoxFlat.new()
	hover_sb.bg_color = Color(0.15, 0.12, 0.22, 0.95)
	hover_sb.border_color = Color(0.95, 0.85, 0.3, 0.95)
	hover_sb.border_width_left   = 2
	hover_sb.border_width_right  = 2
	hover_sb.border_width_top    = 4
	hover_sb.border_width_bottom = 2
	hover_sb.corner_radius_top_left     = 2
	hover_sb.corner_radius_top_right    = 2
	hover_sb.corner_radius_bottom_left  = 2
	hover_sb.corner_radius_bottom_right = 2
	btn.add_theme_stylebox_override("hover", hover_sb)
	return btn
