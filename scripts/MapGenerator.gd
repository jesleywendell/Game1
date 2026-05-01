extends Node2D

const TILE_W := 32
const TILE_H := 32
const MAP_COLS := 132
const MAP_ROWS := 102
const TILE_PATH := "res://assets/isometric tileset/isometric tileset/separated images/tile_%03d.png"
const NEW_ASSETS := "res://assets/"
const CURSED_ASSETS := "res://assets/Free-Cursed-Land-Top-Down-Pixel-Art-Tileset/PNG/Objects_separetely/"

# Phase 1 tiles
const TILES_DARK_SOIL := [12, 13, 14]
const TILES_MOSSY     := [20, 21, 22, 23]
const TILES_GREEN     := [34, 35, 36]
const TILES_BORDER    := [60, 61]
const TILES_ROCKY     := [60, 61]

# Phase 2 tiles — only dark soil + rocky
const TILES_CURSED_FLOOR  := [12, 13, 14]
const TILES_CURSED_ROCKY  := [60, 61]

const INTERIOR_SCATTER: Array[Dictionary] = [
	{"p": "props_decoracao/props_decoracao_006.png",       "z": -5, "s": 0.45},
	{"p": "props_decoracao/props_decoracao_007.png",       "z": -5, "s": 0.40},
	{"p": "props_decoracao/props_decoracao_008.png",       "z": -5, "s": 0.40},
	{"p": "props_decoracao/props_decoracao_009.png",       "z": -5, "s": 0.40},
	{"p": "props_decoracao/props_decoracao_010.png",       "z": -5, "s": 0.40},
	{"p": "props_decoracao/props_decoracao_011.png",       "z": -5, "s": 0.40},
	{"p": "props_decoracao/props_decoracao_012.png",       "z": -5, "s": 0.38},
	{"p": "tombulos_cercas/tombulos_cercas_002.png",       "z": -5, "s": 0.35},
	{"p": "tombulos_cercas/tombulos_cercas_003.png",       "z": -5, "s": 0.35},
	{"p": "tombulos_cercas/tombulos_cercas_004.png",       "z": -5, "s": 0.35},
	{"p": "tombulos_cercas/tombulos_cercas_005.png",       "z": -5, "s": 0.38},
	{"p": "tombulos_cercas/tombulos_cercas_009.png",       "z": -5, "s": 0.38},
	{"p": "tombulos_cercas/tombulos_cercas_010.png",       "z": -5, "s": 0.35},
]

const BORDER_SCATTER: Array[Dictionary] = [
	{"p": "vegetacao_estruturas/vegetacao_estruturas_002.png", "z": -2, "s": 0.55},
	{"p": "vegetacao_estruturas/vegetacao_estruturas_003.png", "z": -2, "s": 0.55},
	{"p": "vegetacao_estruturas/vegetacao_estruturas_004.png", "z": -2, "s": 0.55},
	{"p": "vegetacao_estruturas/vegetacao_estruturas_005.png", "z": -2, "s": 0.55},
	{"p": "vegetacao_estruturas/vegetacao_estruturas_006.png", "z": -2, "s": 0.55},
	{"p": "vegetacao_estruturas/vegetacao_estruturas_007.png", "z": -2, "s": 0.55},
	{"p": "vegetacao_estruturas/vegetacao_estruturas_008.png", "z": -2, "s": 0.50},
	{"p": "vegetacao_estruturas/vegetacao_estruturas_009.png", "z": -2, "s": 0.50},
	{"p": "vegetacao_estruturas/vegetacao_estruturas_015.png", "z": -2, "s": 0.50},
	{"p": "vegetacao_estruturas/vegetacao_estruturas_016.png", "z": -2, "s": 0.50},
	{"p": "vegetacao_estruturas/vegetacao_estruturas_017.png", "z": -2, "s": 0.50},
	{"p": "vegetacao_estruturas/vegetacao_estruturas_018.png", "z": -2, "s": 0.50},
	{"p": "vegetacao_estruturas/vegetacao_estruturas_019.png", "z": -2, "s": 0.50},
]

# Phase 2 scatter — cursed land objects
const CURSED_INTERIOR: Array[String] = [
	"Bones_shadow1_1.png",
	"Bones_shadow1_4.png",
	"Bones_shadow1_7.png",
	"Bones_shadow1_10.png",
	"Rock1_shadow1_1.png",
	"Rock1_shadow1_3.png",
	"Rock3_shadow1_1.png",
	"Rock_eyes_shadow1_1.png",
	"Veins_shadow1_1.png",
	"Ruins_shadow1_3.png",
	"Ruins_shadow1_5.png",
]

const CURSED_BORDER: Array[String] = [
	"Spike_plant_shadow1_1.png",
	"Tentacle_plant_shadow1_1.png",
	"Tentacle_plant_shadow1_2.png",
	"Eye_plant_shadow1_1.png",
	"Ruins_shadow1_4.png",
	"Ruins_shadow1_6.png",
]

var _occupied := {}

func _ready() -> void:
	var area := ProgressionManager.get_current_area()
	var noise_scatter := FastNoiseLite.new()
	noise_scatter.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_scatter.frequency = 0.18

	if area <= 1:
		noise_scatter.seed = 42
		_generate_forest()
		_spawn_scatter(noise_scatter)
		modulate = Color(0.55, 0.70, 0.55, 1.0)
	else:
		noise_scatter.seed = 91
		_generate_cursed()
		_spawn_cursed_scatter(noise_scatter)
		modulate = Color(0.72, 0.38, 0.38, 1.0)

	_add_border_colliders()

# ── Phase 1 ───────────────────────────────────────────────────────────────────

func _generate_forest() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.1
	for row in MAP_ROWS:
		for col in MAP_COLS:
			var is_border := row == 0 or row == MAP_ROWS - 1 or col == 0 or col == MAP_COLS - 1
			var idx: int
			if is_border:
				idx = TILES_BORDER[_stable_pick(col + row * MAP_COLS, TILES_BORDER.size())]
			else:
				idx = _pick_forest_tile(noise.get_noise_2d(col, row), col, row)
			_place_tile(col, row, idx)

func _pick_forest_tile(n: float, col: int, row: int) -> int:
	var s := col * 31 + row * 97
	if n < -0.15: return TILES_DARK_SOIL[_stable_pick(s, TILES_DARK_SOIL.size())]
	elif n < 0.15: return TILES_MOSSY[_stable_pick(s, TILES_MOSSY.size())]
	elif n < 0.45: return TILES_GREEN[_stable_pick(s, TILES_GREEN.size())]
	else: return TILES_ROCKY[_stable_pick(s, TILES_ROCKY.size())]

func _spawn_scatter(noise_scatter: FastNoiseLite) -> void:
	for row in MAP_ROWS:
		for col in MAP_COLS:
			if noise_scatter.get_noise_2d(col, row) < 0.25: continue
			if _occupied.has(Vector2i(col, row)): continue
			var border_zone := row <= 3 or row >= MAP_ROWS - 4 or col <= 3 or col >= MAP_COLS - 4
			if row == 0 or row == MAP_ROWS - 1 or col == 0 or col == MAP_COLS - 1: continue
			var sv := col * 31 + row * 97
			if border_zone:
				_place_scatter_from_list(col, row, sv, BORDER_SCATTER, NEW_ASSETS)
			else:
				_place_scatter_from_list(col, row, sv, INTERIOR_SCATTER, NEW_ASSETS)

# ── Phase 2 ───────────────────────────────────────────────────────────────────

func _generate_cursed() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 37
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.12
	for row in MAP_ROWS:
		for col in MAP_COLS:
			var is_border := row == 0 or row == MAP_ROWS - 1 or col == 0 or col == MAP_COLS - 1
			var idx: int
			if is_border:
				idx = TILES_BORDER[_stable_pick(col + row * MAP_COLS, TILES_BORDER.size())]
			else:
				var n := noise.get_noise_2d(col, row)
				var s := col * 31 + row * 97
				if n < 0.25:
					idx = TILES_CURSED_FLOOR[_stable_pick(s, TILES_CURSED_FLOOR.size())]
				else:
					idx = TILES_CURSED_ROCKY[_stable_pick(s, TILES_CURSED_ROCKY.size())]
			_place_tile(col, row, idx)

func _spawn_cursed_scatter(noise_scatter: FastNoiseLite) -> void:
	for row in MAP_ROWS:
		for col in MAP_COLS:
			if noise_scatter.get_noise_2d(col, row) < 0.30: continue
			if _occupied.has(Vector2i(col, row)): continue
			if row == 0 or row == MAP_ROWS - 1 or col == 0 or col == MAP_COLS - 1: continue
			var border_zone := row <= 3 or row >= MAP_ROWS - 4 or col <= 3 or col >= MAP_COLS - 4
			var sv := col * 31 + row * 97
			if border_zone:
				_place_cursed_object(col, row, sv, CURSED_BORDER, -2, 0.40)
			else:
				_place_cursed_object(col, row, sv, CURSED_INTERIOR, -5, 0.35)

func _place_cursed_object(col: int, row: int, sv: int, arr: Array, z: int, s: float) -> void:
	var file: String = arr[abs(sv) % arr.size()]
	var path := CURSED_ASSETS + file
	if not ResourceLoader.exists(path): return
	var spr := Sprite2D.new()
	spr.texture = load(path)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.position = Vector2((col - row) * TILE_W / 2.0, (col + row) * TILE_H / 4.0)
	spr.z_index = z
	spr.scale = Vector2(s, s)
	add_child(spr)
	_mark_occupied(col, row)

# ── Border colliders ──────────────────────────────────────────────────────────

func _add_border_colliders() -> void:
	# Diamond corners in world space
	var tl := Vector2(0.0, 0.0)
	var tr := Vector2((MAP_COLS - 1) * TILE_W / 2.0, (MAP_COLS - 1) * TILE_H / 4.0)
	var bl := Vector2(-(MAP_ROWS - 1) * TILE_W / 2.0, (MAP_ROWS - 1) * TILE_H / 4.0)
	var br := tr + bl

	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask  = 0
	for edge in [[tl, tr], [tr, br], [br, bl], [bl, tl]]:
		var seg := SegmentShape2D.new()
		seg.a = edge[0]
		seg.b = edge[1]
		var cs := CollisionShape2D.new()
		cs.shape = seg
		body.add_child(cs)
	add_child(body)

# ── Shared helpers ────────────────────────────────────────────────────────────

func _stable_pick(seed_val: int, count: int) -> int:
	return abs(seed_val) % count

func _place_tile(col: int, row: int, tile_index: int) -> void:
	tile_index = clampi(tile_index, 0, 114)
	var spr := Sprite2D.new()
	spr.texture = load(TILE_PATH % tile_index)
	spr.position = Vector2((col - row) * TILE_W / 2.0, (col + row) * TILE_H / 4.0)
	spr.z_index = -10
	add_child(spr)

func _place_scatter_from_list(col: int, row: int, sv: int, list: Array, base: String) -> void:
	var e: Dictionary = list[abs(sv) % list.size()]
	var path: String = base + str(e["p"])
	if not ResourceLoader.exists(path): return
	var spr := Sprite2D.new()
	spr.texture = load(path)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.position = Vector2((col - row) * TILE_W / 2.0, (col + row) * TILE_H / 4.0)
	spr.z_index = int(e["z"])
	spr.scale = Vector2(float(e["s"]), float(e["s"]))
	add_child(spr)
	_mark_occupied(col, row)

func _mark_occupied(col: int, row: int) -> void:
	for dc in [-1, 0, 1]:
		for dr in [-1, 0, 1]:
			_occupied[Vector2i(col + dc, row + dr)] = true
