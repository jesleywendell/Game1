extends Node2D

const TILE_PATH    := "res://assets/isometric tileset/isometric tileset/separated images/tile_%03d.png"
const TILES_HUB    := [34, 35, 36]
const TILES_PATH   := [20, 21, 22, 23]
const TILES_EDGE   := [60, 61]
const NPC_SPRITE     := "res://assets/props_decoracao/props_decoracao_001.png"
const PORTAL_SPRITE  := "res://assets/edificacoes_grandes/edificacoes_grandes_001.png"

const PLAYER_SCENE := preload("res://scenes/Player.tscn")

const TILE_W    := 32
const TILE_H    := 32
const MAP_COLS  := 20
const MAP_ROWS  := 14

const PATH_SEGMENTS := [
	{"col": 3,  "row_min": 4, "row_max": 7},
	{"col": 5,  "row_min": 4, "row_max": 8},
	{"col": 7,  "row_min": 5, "row_max": 9},
	{"col": 8,  "row_min": 4, "row_max": 7},
	{"col": 10, "row_min": 5, "row_max": 9},
	{"col": 12, "row_min": 6, "row_max": 10},
	{"col": 14, "row_min": 5, "row_max": 8},
	{"col": 15, "row_min": 3, "row_max": 6},
	{"col": 16, "row_min": 2, "row_max": 5},
]

const PLAYER_COL := 7;  const PLAYER_ROW := 8
const NPC_COL    := 2;  const NPC_ROW    := 4
const EXIT_COL   := 16; const EXIT_ROW   := 3

var _player: CharacterBody2D
var _player_near_exit := false
var _player_near_mercador := false
var _frag_label: Label
var _background_rect: ColorRect
var _time_accum: float = 0.0
var _mercador_lbl: Label
var _floresta_lbl: Label
var _portal_light: PointLight2D
var _light_texture: GradientTexture2D

func _ready() -> void:
	_setup_atmosphere()
	
	var cm := CanvasModulate.new()
	cm.color = Color(0.22, 0.24, 0.28, 1.0)
	add_child(cm)

	var grad := Gradient.new()
	grad.add_point(0.0, Color.WHITE)
	grad.add_point(0.35, Color(1, 1, 1, 0.7))
	grad.add_point(0.75, Color(1, 1, 1, 0.15))
	grad.add_point(1.0, Color(1, 1, 1, 0.0))
	_light_texture = GradientTexture2D.new()
	_light_texture.gradient = grad
	_light_texture.width = 256
	_light_texture.height = 256
	_light_texture.fill = GradientTexture2D.FILL_RADIAL
	_light_texture.fill_from = Vector2(0.5, 0.5)
	_build_map()
	_spawn_player()
	_spawn_npc()
	_spawn_exit()
	_setup_foreground()
	_build_hud()
	ProgressionManager.fragments_changed.connect(func(_n): _refresh_hud())
	_refresh_hud()

func _process(delta: float) -> void:
	_time_accum += delta
	if _background_rect and _background_rect.material:
		_background_rect.material.set_shader_parameter("time", _time_accum)
	if _player:
		if _mercador_lbl:
			_mercador_lbl.visible = _player_near_mercador
		if _floresta_lbl:
			_floresta_lbl.visible = _player_near_exit
	if _portal_light:
		_portal_light.energy = 0.6 + sin(_time_accum * 2.0) * 0.8
	if _player:
		var cam := _player.get_node("Camera2D") as Camera2D
		if cam:
			cam.offset = Vector2(sin(_time_accum * 0.3) * 3.0, cos(_time_accum * 0.4) * 3.0)

# ── Atmosphere ─────────────────────────────────────────────────────────────────

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

# ── Map ───────────────────────────────────────────────────────────────────────

func _iso(col: int, row: int) -> Vector2:
	return Vector2((col - row) * TILE_W / 2.0, (col + row) * TILE_H / 4.0)

func _pick(seed_val: int, count: int) -> int:
	return abs(seed_val * 1013904223 + 1664525) % count

func _build_map() -> void:
	for row in MAP_ROWS:
		for col in MAP_COLS:
			var border := col == 0 or col == MAP_COLS - 1 or row == 0 or row == MAP_ROWS - 1
			var on_path := false
			for seg in PATH_SEGMENTS:
				var s := seg as Dictionary
				if col == s["col"] and row >= s["row_min"] and row <= s["row_max"]:
					on_path = true
					break
			if border:
				var corner_cut := false
				if col + row < 5:
					corner_cut = true
				elif (MAP_COLS - 1 - col) + row < 5:
					corner_cut = true
				elif (MAP_COLS - 1 - col) + (MAP_ROWS - 1 - row) < 5:
					corner_cut = true
				elif col + (MAP_ROWS - 1 - row) < 6:
					corner_cut = true
				if corner_cut:
					continue
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
			if border:
				spr.modulate = Color(0.20, 0.18, 0.28)
				var body := StaticBody2D.new()
				body.collision_layer = 1
				body.collision_mask = 0
				var shape := CollisionPolygon2D.new()
				shape.polygon = PackedVector2Array([Vector2(0, -10), Vector2(18, 0), Vector2(0, 10), Vector2(-18, 0)])
				body.add_child(shape)
				spr.add_child(body)
			elif on_path:
				spr.modulate = Color(0.42, 0.40, 0.35)
			else:
				spr.modulate = Color(0.25, 0.35, 0.28)
			add_child(spr)

	var edge_props := [
		{"col": 1, "row": 0, "spr": "props_decoracao_002"},
		{"col": 18, "row": 0, "spr": "props_decoracao_003"},
		{"col": 0, "row": 3, "spr": "props_decoracao_004"},
		{"col": 19, "row": 4, "spr": "props_decoracao_006"},
		{"col": 2, "row": 13, "spr": "props_decoracao_007"},
		{"col": 17, "row": 13, "spr": "props_decoracao_008"},
		{"col": 0, "row": 11, "spr": "props_decoracao_009"},
		{"col": 19, "row": 10, "spr": "props_decoracao_010"},
	]
	var asset_root := "res://assets/props_decoracao/"
	for ep in edge_props:
		var pvar := ep as Dictionary
		var pspr := Sprite2D.new()
		pspr.texture = load(asset_root + pvar["spr"] + ".png")
		pspr.position = _iso(pvar["col"], pvar["row"])
		pspr.z_index = -9
		pspr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pspr.modulate = Color(0.28, 0.32, 0.28)
		add_child(pspr)

	var edge_veg := [
		{"col": 1, "row": 1,  "sprite": "vegetacao_estruturas_002"},
		{"col": 18, "row": 1, "sprite": "vegetacao_estruturas_004"},
		{"col": 0, "row": 5,  "sprite": "vegetacao_estruturas_006"},
		{"col": 19, "row": 6, "sprite": "vegetacao_estruturas_008"},
		{"col": 3, "row": 13, "sprite": "vegetacao_estruturas_010"},
		{"col": 16, "row": 13,"sprite": "vegetacao_estruturas_012"},
	]
	var veg_root := "res://assets/vegetacao_estruturas/"
	for ve in edge_veg:
		var d := ve as Dictionary
		var vspr := Sprite2D.new()
		vspr.texture = load(veg_root + d["sprite"] + ".png")
		vspr.position = _iso(d["col"], d["row"])
		vspr.z_index = -8
		vspr.scale = Vector2(1.2, 1.2)
		vspr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		vspr.modulate = Color(0.18, 0.22, 0.18)
		add_child(vspr)

# ── Player ────────────────────────────────────────────────────────────────────

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
	light.range_z_max = 10
	_player.add_child(light)
	_player.died.connect(func():
		TransitionScreen.fade_to("res://scenes/MainMenu.tscn")
	)

	var bone_clusters := [
		{"col": 11, "row": 6, "sprite": 3,  "rot": 0.2,  "mod": Color(0.35, 0.38, 0.32)},
		{"col": 11, "row": 7, "sprite": 7,  "rot": -0.1, "mod": Color(0.32, 0.35, 0.30)},
		{"col": 12, "row": 6, "sprite": 11, "rot": 0.4,  "mod": Color(0.30, 0.33, 0.28)},
		{"col": 10, "row": 7, "sprite": 14, "rot": -0.3, "mod": Color(0.33, 0.36, 0.31)},
		{"col": 4,  "row": 11, "sprite": 2,  "rot": -0.4, "mod": Color(0.30, 0.33, 0.28)},
		{"col": 5,  "row": 12, "sprite": 6,  "rot": 0.3,  "mod": Color(0.28, 0.31, 0.26)},
		{"col": 3,  "row": 12, "sprite": 9,  "rot": 0.1,  "mod": Color(0.32, 0.35, 0.30)},
	]
	for bc in bone_clusters:
		var d := bc as Dictionary
		var bspr := Sprite2D.new()
		bspr.texture = load("res://assets/forest/Bones_shadow1_%d.png" % d["sprite"])
		bspr.position = _iso(d["col"], d["row"])
		bspr.z_index = -9
		bspr.rotation = d["rot"]
		bspr.modulate = d["mod"]
		bspr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(bspr)

# ── NPC ───────────────────────────────────────────────────────────────────────

func _spawn_npc() -> void:
	var pos := _iso(NPC_COL, NPC_ROW)

	var spr := Sprite2D.new()
	spr.texture = load(NPC_SPRITE)
	spr.position = pos
	spr.z_index = 1
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(spr)

	var light := PointLight2D.new()
	light.color = Color(1.0, 0.55, 0.2)
	light.energy = 1.2
	light.texture = _light_texture
	light.texture_scale = 2.2
	light.z_index = 5
	light.range_z_min = -10
	light.range_z_max = 10
	light.position = pos + Vector2(0, 8)
	add_child(light)

	var camp_props := [
		{"path": "res://assets/edificacoes_pequenas/edificacoes_pequenas_001.png", "offset": Vector2(-36, -14), "z": 0, "scale": Vector2(0.7, 0.7), "mod": Color(0.35, 0.40, 0.35)},
		{"path": "res://assets/edificacoes_pequenas/edificacoes_pequenas_002.png", "offset": Vector2(20, -10),  "z": 0, "scale": Vector2(0.7, 0.7), "mod": Color(0.32, 0.38, 0.32)},
		{"path": "res://assets/tombulos_cercas/tombulos_cercas_001.png",      "offset": Vector2(-28, 6),   "z": 1, "scale": Vector2(0.8, 0.8), "mod": Color(0.4, 0.4, 0.4)},
		{"path": "res://assets/tombulos_cercas/tombulos_cercas_002.png",      "offset": Vector2(18, 8),    "z": 1, "scale": Vector2(0.8, 0.8), "mod": Color(0.4, 0.4, 0.4)},
		{"path": "res://assets/props_decoracao/props_decoracao_007.png", "offset": Vector2(-14, 12),  "z": 1, "scale": Vector2(0.6, 0.6), "mod": Color(0.55, 0.5, 0.35)},
		{"path": "res://assets/props_decoracao/props_decoracao_008.png", "offset": Vector2(8, 14),    "z": 1, "scale": Vector2(0.6, 0.6), "mod": Color(0.55, 0.5, 0.35)},
		{"path": "res://assets/props_decoracao/props_decoracao_009.png", "offset": Vector2(-4, 16),   "z": 1, "scale": Vector2(0.6, 0.6), "mod": Color(0.55, 0.5, 0.35)},
	]
	for cp in camp_props:
		var d := cp as Dictionary
		var pspr := Sprite2D.new()
		pspr.texture = load(d["path"])
		pspr.position = pos + d["offset"]
		pspr.z_index = d["z"]
		pspr.scale = d["scale"]
		pspr.modulate = d["mod"]
		pspr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(pspr)

	var occluder_shapes := [
		pos + Vector2(-36, -14),
		pos + Vector2(20, -10),
		pos + Vector2(-28, 6),
		pos + Vector2(18, 8),
	]
	for occ_pos in occluder_shapes:
		var occluder := LightOccluder2D.new()
		occluder.position = occ_pos
		var occ_poly := OccluderPolygon2D.new()
		occ_poly.polygon = PackedVector2Array([Vector2(-14, -18), Vector2(14, -10), Vector2(14, 18), Vector2(-14, 10)])
		occluder.occluder = occ_poly
		add_child(occluder)

	_mercador_lbl = Label.new()
	_mercador_lbl.text = "Mercador"
	_mercador_lbl.add_theme_font_size_override("font_size", 9)
	_mercador_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	_mercador_lbl.position = pos + Vector2(-28, -42)
	_mercador_lbl.z_index = 5
	_mercador_lbl.visible = false
	add_child(_mercador_lbl)

	var area := Area2D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(80.0, 64.0)
	shape.shape = rect
	area.add_child(shape)
	area.body_entered.connect(func(b):
		if b == _player and not _player_near_mercador:
			_player_near_mercador = true
			_show_mercador_prompt()
	)
	area.body_exited.connect(func(b):
		if b == _player:
			_player_near_mercador = false
	)
	add_child(area)

# ── Exit zone ─────────────────────────────────────────────────────────────────

func _spawn_exit() -> void:
	var pos := _iso(EXIT_COL, EXIT_ROW)

	var spr := Sprite2D.new()
	spr.texture = load(PORTAL_SPRITE)
	spr.position = pos
	spr.z_index = 0
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(spr)

	_portal_light = PointLight2D.new()
	_portal_light.color = Color(0.95, 0.1, 0.05)
	_portal_light.energy = 1.0
	_portal_light.texture = _light_texture
	_portal_light.texture_scale = 2.8
	_portal_light.z_index = 5
	_portal_light.range_z_min = -10
	_portal_light.range_z_max = 10
	add_child(_portal_light)

	var portal_particles := CPUParticles2D.new()
	portal_particles.emitting = true
	portal_particles.amount = 20
	portal_particles.lifetime = 2.5
	portal_particles.one_shot = false
	portal_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	portal_particles.emission_sphere_radius = 32.0
	portal_particles.position = pos
	portal_particles.direction = Vector2(0.0, -1.0)
	portal_particles.spread = 60.0
	portal_particles.gravity = Vector2(0.0, -8.0)
	portal_particles.initial_velocity_min = 6.0
	portal_particles.initial_velocity_max = 18.0
	portal_particles.scale_amount_min = 2.0
	portal_particles.scale_amount_max = 5.0
	portal_particles.color = Color(0.95, 0.2, 0.05, 0.4)
	portal_particles.z_index = 3
	add_child(portal_particles)

	spr.scale = Vector2(1.4, 1.4)
	spr.modulate = Color(0.75, 0.35, 0.25)

	_floresta_lbl = Label.new()
	_floresta_lbl.text = "O Caminho"
	_floresta_lbl.add_theme_font_size_override("font_size", 9)
	_floresta_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.5))
	_floresta_lbl.position = pos + Vector2(-22, -42)
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
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.06, 0.95)
	sb.border_color = Color(0.85, 0.65, 0.15, 0.8)
	sb.border_width_left   = 3
	sb.border_width_right  = 3
	sb.border_width_top    = 3
	sb.border_width_bottom = 3
	sb.corner_radius_top_left     = 0
	sb.corner_radius_top_right    = 0
	sb.corner_radius_bottom_left  = 0
	sb.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(12, 12)
	panel.size = Vector2(190, 42)
	cl.add_child(panel)
	_frag_label = Label.new()
	_frag_label.add_theme_font_size_override("font_size", 19)
	_frag_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	_frag_label.position = Vector2(24, 23)
	cl.add_child(_frag_label)

func _refresh_hud() -> void:
	if _frag_label:
		_frag_label.text = "✦ %d Fragmentos" % ProgressionManager.get_fragments()

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

	var bush_left := Sprite2D.new()
	bush_left.texture = load("res://assets/vegetacao_estruturas/vegetacao_estruturas_001.png")
	bush_left.position = Vector2(40, 990)
	bush_left.z_index = 0
	bush_left.scale = Vector2(2.0, 2.0)
	bush_left.modulate = Color(0.05, 0.06, 0.05)
	bush_left.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fg_layer.add_child(bush_left)

	var bush_right := Sprite2D.new()
	bush_right.texture = load("res://assets/vegetacao_estruturas/vegetacao_estruturas_003.png")
	bush_right.position = Vector2(1760, 960)
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
	top_right.position = Vector2(1720, -80)
	top_right.z_index = 0
	top_right.scale = Vector2(3.2, 3.2)
	top_right.modulate = Color(0.04, 0.04, 0.06)
	top_right.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fg_layer.add_child(top_right)

	var side_right := Sprite2D.new()
	side_right.texture = load("res://assets/edificacoes_pequenas/edificacoes_pequenas_008.png")
	side_right.position = Vector2(1780, 300)
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
	accent.add_theme_color_override("font_color", Color(0.55, 0.35, 0.1, 0.8))
	vbox.add_child(accent)

	_make_label(vbox, "Seguir pelo Caminho?", 32, Color(0.9, 0.55, 0.2))
	_make_label(vbox, "A redenção exige sacrifício.", 15, Color(0.7, 0.55, 0.55))

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

	var sep2 := Control.new()
	sep2.custom_minimum_size = Vector2(0, 8)
	sep2.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(sep2)

	var nj_btn := _make_button("Recome\u00e7ar Jornada", 18, 220)
	nj_btn.add_theme_color_override("font_color", Color(0.6, 0.9, 0.5))
	nj_btn.pressed.connect(func():
		ProgressionManager.reset_level()
		ProgressionManager.data.current_area = 1
		ProgressionManager.save()
		get_tree().paused = false
		TransitionScreen.fade_to("res://scenes/World.tscn")
	)
	vbox.add_child(nj_btn)

# ── Mercador prompt ────────────────────────────────────────────────────────────

func _show_mercador_prompt() -> void:
	get_tree().paused = true
	var cl := _make_overlay(20, "MercadorPrompt")
	var vbox := _make_vbox(cl, 360)

	var accent := Label.new()
	accent.text = "◆  ◆  ◆"
	accent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	accent.add_theme_font_size_override("font_size", 12)
	accent.add_theme_color_override("font_color", Color(0.55, 0.35, 0.1, 0.8))
	vbox.add_child(accent)

	_make_label(vbox, "Mercador", 36, Color(0.95, 0.85, 0.3))

	var hsep := HSeparator.new()
	hsep.add_theme_color_override("color", Color(0.75, 0.63, 0.19, 0.5))
	hsep.custom_minimum_size = Vector2(300, 2)
	vbox.add_child(hsep)

	_make_label(vbox, "O com\u00e9rcio da alma nunca cessa.", 16, Color(0.65, 0.6, 0.6))
	_make_label(vbox, "\u2726 %d Fragmentos da Alma" % ProgressionManager.get_fragments(), 22, Color(0.95, 0.85, 0.3))

	var vol := _make_button("Voltar", 20, 160)
	vol.pressed.connect(func():
		get_tree().paused = false
		_player_near_mercador = false
		cl.queue_free()
	)
	vbox.add_child(vol)

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
