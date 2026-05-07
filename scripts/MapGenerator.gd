extends Node2D

const TILE_W := 32
const TILE_H := 32
const MAP_COLS := 120
const MAP_ROWS := 120
const TILE_PATH    := "res://assets/isometric tileset/isometric tileset/separated images/tile_%03d.png"
const FOREST_ASSETS  := "res://assets/forest/"
const CURSED_ASSETS  := "res://assets/Free-Cursed-Land-Top-Down-Pixel-Art-Tileset/PNG/Objects_separetely/"
const UNDEAD_ASSETS  := "res://assets/Free-Undead-Tileset-Top-Down-Pixel-Art/PNG/Objects_separately/"

# ── Tile pools ────────────────────────────────────────────────────────────────

# Phase 1 — Rotten Forest
const TILES_DARK_SOIL := [12, 13, 14]
const TILES_MOSSY     := [20, 21, 22, 23]
const TILES_GREEN     := [34, 35, 36]
const TILES_ROCKY     := [60, 61]
const TILES_BORDER    := [60, 61]

# Phase 2 — Cursed Land  (3 zones: cracked soil / sickly moss / corrupted rock)
const TILES_CURSED_FLOOR := [12, 13, 14]
const TILES_CURSED_MID   := [20, 21, 22, 23]
const TILES_CURSED_ROCKY := [60, 61]

# Phase 3 — Undead Cemetery  (stone floor with dark soil veins)
const TILES_UNDEAD_FLOOR := [60, 61]
const TILES_UNDEAD_PATCH := [12, 13, 14]

# ── Phase 1 scatter — Floresta Podre ─────────────────────────────────────────

const FOREST_INTERIOR: Array[String] = [
	"Bones_shadow1_1.png",  "Bones_shadow1_3.png",  "Bones_shadow1_5.png",
	"Bones_shadow1_8.png",  "Bones_shadow1_11.png", "Bones_shadow1_14.png",
	"Rock_shadow1_1.png",   "Rock_shadow1_2.png",   "Rock_shadow1_3.png",
	"Rock_shadow1_4.png",   "Rock_shadow1_5.png",
	"Plant_shadow1_1.png",  "Plant_shadow1_2.png",  "Plant_shadow1_3.png",
	"Plant_shadow1_4.png",  "Plant_shadow1_5.png",
	"Dead_tree_shadow1_1.png", "Dead_tree_shadow1_2.png", "Dead_tree_shadow1_3.png",
]
const FOREST_BORDER: Array[String] = [
	"Broken_tree_shadow1_1.png", "Broken_tree_shadow1_2.png", "Broken_tree_shadow1_3.png",
	"Broken_tree_shadow1_4.png", "Broken_tree_shadow1_5.png", "Broken_tree_shadow1_6.png",
	"Dead_tree_shadow1_1.png",   "Dead_tree_shadow1_2.png",   "Dead_tree_shadow1_3.png",
	"Thorn_palnt_shadow2_1.png", "Thorn_palnt_shadow2_2.png", "Thorn_palnt_shadow2_3.png",
	"Thorn_palnt_shadow2_4.png", "Thorn_palnt_shadow2_5.png",
]

# ── Phase 2 scatter — Cursed Land ────────────────────────────────────────────

const CURSED_INTERIOR: Array[String] = [
	"Bones_shadow1_1.png",         "Bones_shadow1_2.png",         "Bones_shadow1_4.png",
	"Bones_shadow1_7.png",         "Bones_shadow1_9.png",         "Bones_shadow1_11.png",
	"Bones_shadow2_1.png",         "Bones_shadow2_3.png",         "Bones_shadow2_5.png",
	"Rock1_shadow1_1.png",         "Rock1_shadow1_2.png",         "Rock1_shadow1_3.png",
	"Rock1_shadow1_4.png",
	"Rock2_shadow2_1.png",         "Rock2_shadow2_2.png",         "Rock2_shadow2_3.png",
	"Rock3_shadow1_1.png",         "Rock3_shadow1_2.png",         "Rock3_shadow1_3.png",
	"Rock3_shadow2_1.png",         "Rock3_shadow2_2.png",
	"Rock_eyes_shadow1_1.png",     "Rock_eyes_shadow1_2.png",     "Rock_eyes_shadow1_3.png",
	"Veins_shadow1_1.png",
	"Ruins_shadow1_3.png",         "Ruins_shadow1_4.png",         "Ruins_shadow1_5.png",
	"Fetus_shadow1_1.png",         "Fetus_shadow1_2.png",
	"Pustules_shadow1_1.png",      "Pustules_shadow1_2.png",      "Pustules_shadow1_3.png",
	"Many_eyes_plant_shadow1_1.png","Many_eyes_plant_shadow1_2.png","Many_eyes_plant_shadow1_3.png",
]
const CURSED_BORDER: Array[String] = [
	"Spike_plant_shadow1_1.png",   "Spike_plant_shadow1_2.png",
	"Tentacle_plant_shadow1_1.png","Tentacle_plant_shadow1_2.png","Tentacle_plant_shadow1_3.png",
	"Eye_plant_shadow1_1.png",     "Eye_plant_shadow1_2.png",     "Eye_plant_shadow1_3.png",
	"Jaws_plant_shadow1_1.png",    "Jaws_plant_shadow1_2.png",    "Jaws_plant_shadow1_3.png",
	"Meat_flower_shadow1_1.png",   "Meat_flower_shadow1_2.png",
	"Ruins_shadow1_5.png",         "Ruins_shadow1_6.png",
	"Ruins_shadow2_1.png",         "Ruins_shadow2_2.png",         "Ruins_shadow2_3.png",
]

# ── Phase 3 scatter — Undead Cemetery ────────────────────────────────────────

const UNDEAD_INTERIOR: Array[String] = [
	"Grave_shadow1_1.png",     "Grave_shadow1_4.png",     "Grave_shadow1_7.png",
	"Grave_shadow1_11.png",    "Grave_shadow1_15.png",
	"Bones_shadow1_1.png",     "Bones_shadow1_3.png",     "Bones_shadow1_5.png",
	"Bones_shadow1_8.png",     "Bones_shadow1_12.png",    "Bones_shadow1_15.png",
	"Bones_shadow2_1.png",     "Bones_shadow2_4.png",     "Bones_shadow2_7.png",
	"Bones_shadow3_1.png",     "Bones_shadow3_5.png",
	"Crystal_shadow1_1.png",   "Crystal_shadow1_2.png",   "Crystal_shadow1_3.png",
	"Crystal_shadow2_1.png",   "Crystal_shadow2_2.png",
	"Dead_arm_shadow1_1.png",  "Dead_arm_shadow1_2.png",  "Dead_arm_shadow1_3.png",
	"Dead_arm_shadow2_1.png",  "Dead_arm_shadow2_2.png",
	"Pile_sculls_shadow1.png", "Pile_sculls_shadow2.png",
	"Rock_shadow1_1.png",      "Rock_shadow1_2.png",      "Rock_shadow1_3.png",
	"Ruin_shadow1_1.png",      "Ruin_shadow1_4.png",
]
const UNDEAD_BORDER: Array[String] = [
	"Broken_tree_shadow1_1.png", "Broken_tree_shadow1_2.png", "Broken_tree_shadow1_3.png",
	"Broken_tree_shadow1_4.png", "Broken_tree_shadow1_5.png", "Broken_tree_shadow1_6.png",
	"Broken_tree_shadow2_1.png", "Broken_tree_shadow2_2.png", "Broken_tree_shadow2_3.png",
	"Dead_tree_shadow1_1.png",   "Dead_tree_shadow1_2.png",   "Dead_tree_shadow1_3.png",
	"Thorn_plant_shadow1_1.png", "Thorn_plant_shadow1_2.png", "Thorn_plant_shadow1_3.png",
	"Lich_shadow1.png",          "Lich_shadow2.png",
]

var _tex_cache: Dictionary = {}
var _occupied := {}

func _ready() -> void:
	var area := ProgressionManager.get_current_area()
	var noise_scatter := FastNoiseLite.new()
	noise_scatter.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_scatter.frequency = 0.18

	if area <= 1:
		noise_scatter.seed = 42
		_generate_forest()
		_spawn_area_scatter(noise_scatter, FOREST_INTERIOR, FOREST_BORDER, FOREST_ASSETS, 0.22, 0.38, 0.48)
		modulate = Color(0.52, 0.68, 0.52, 1.0)
	elif area == 2:
		noise_scatter.seed = 91
		_generate_cursed()
		_spawn_area_scatter(noise_scatter, CURSED_INTERIOR, CURSED_BORDER, CURSED_ASSETS, 0.22, 0.38, 0.45)
		modulate = Color(0.68, 0.34, 0.34, 1.0)
	else:
		noise_scatter.seed = 63
		_generate_undead()
		_spawn_area_scatter(noise_scatter, UNDEAD_INTERIOR, UNDEAD_BORDER, UNDEAD_ASSETS, 0.20, 0.40, 0.50)
		modulate = Color(0.36, 0.38, 0.56, 1.0)

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

# ── Phase 2 ───────────────────────────────────────────────────────────────────

func _generate_cursed() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 37
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.10
	var noise2 := FastNoiseLite.new()
	noise2.seed = 113
	noise2.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise2.frequency = 0.06
	for row in MAP_ROWS:
		for col in MAP_COLS:
			var is_border := row == 0 or row == MAP_ROWS - 1 or col == 0 or col == MAP_COLS - 1
			var idx: int
			if is_border:
				idx = TILES_BORDER[_stable_pick(col + row * MAP_COLS, TILES_BORDER.size())]
			else:
				var n  := noise.get_noise_2d(col, row)
				var n2 := noise2.get_noise_2d(col, row)
				var s  := col * 31 + row * 97
				if n < -0.10:
					idx = TILES_CURSED_FLOOR[_stable_pick(s, TILES_CURSED_FLOOR.size())]
				elif n < 0.20 or n2 < -0.20:
					idx = TILES_CURSED_MID[_stable_pick(s, TILES_CURSED_MID.size())]
				else:
					idx = TILES_CURSED_ROCKY[_stable_pick(s, TILES_CURSED_ROCKY.size())]
			_place_tile(col, row, idx)

# ── Phase 3 ───────────────────────────────────────────────────────────────────

func _generate_undead() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 59
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.09
	for row in MAP_ROWS:
		for col in MAP_COLS:
			var is_border := row == 0 or row == MAP_ROWS - 1 or col == 0 or col == MAP_COLS - 1
			var idx: int
			if is_border:
				idx = TILES_BORDER[_stable_pick(col + row * MAP_COLS, TILES_BORDER.size())]
			else:
				var n := noise.get_noise_2d(col, row)
				var s := col * 31 + row * 97
				if n < 0.15:
					idx = TILES_UNDEAD_PATCH[_stable_pick(s, TILES_UNDEAD_PATCH.size())]
				else:
					idx = TILES_UNDEAD_FLOOR[_stable_pick(s, TILES_UNDEAD_FLOOR.size())]
			_place_tile(col, row, idx)

# ── Scatter (shared) ──────────────────────────────────────────────────────────

func _spawn_area_scatter(
		noise_scatter: FastNoiseLite,
		interior: Array, border: Array,
		base: String, threshold: float,
		s_interior: float, s_border: float) -> void:
	for row in MAP_ROWS:
		for col in MAP_COLS:
			if noise_scatter.get_noise_2d(col, row) < threshold: continue
			if _occupied.has(Vector2i(col, row)): continue
			if row == 0 or row == MAP_ROWS - 1 or col == 0 or col == MAP_COLS - 1: continue
			var border_zone := row <= 4 or row >= MAP_ROWS - 5 or col <= 4 or col >= MAP_COLS - 5
			var sv := col * 31 + row * 97
			if border_zone:
				_place_named_object(col, row, sv, border, base, -2, s_border)
			else:
				_place_named_object(col, row, sv, interior, base, -5, s_interior)

func _place_named_object(col: int, row: int, sv: int, arr: Array, base: String, z: int, s: float) -> void:
	if arr.is_empty(): return
	var file: String = arr[abs(sv) % arr.size()]
	var path: String = base + file
	if not ResourceLoader.exists(path): return
	# Deterministic scale variation ±20 % based on position seed
	var scale_mul := 0.82 + 0.36 * float(abs(sv * 7 + 31) % 100) / 100.0
	var world_pos := Vector2((col - row) * TILE_W / 2.0, (col + row) * TILE_H / 4.0)
	var spr := Sprite2D.new()
	spr.texture = _get_tex(path)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.position = world_pos
	spr.z_index = z
	spr.scale = Vector2(s * scale_mul, s * scale_mul)
	add_child(spr)

	_mark_occupied(col, row)

# ── Border colliders ──────────────────────────────────────────────────────────

func _add_border_colliders() -> void:
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

func _get_tex(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path)
	return _tex_cache[path]

func _place_tile(col: int, row: int, tile_index: int) -> void:
	tile_index = clampi(tile_index, 0, 114)
	var spr := Sprite2D.new()
	spr.texture = _get_tex(TILE_PATH % tile_index)
	spr.position = Vector2((col - row) * TILE_W / 2.0, (col + row) * TILE_H / 4.0)
	spr.z_index = -10
	add_child(spr)

func _mark_occupied(col: int, row: int) -> void:
	for dc in [-1, 0, 1]:
		for dr in [-1, 0, 1]:
			_occupied[Vector2i(col + dc, row + dr)] = true
