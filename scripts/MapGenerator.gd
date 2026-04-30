extends Node2D

# Corrupted rotten forest map generator
# Tiles are 32x32px arranged in isometric projection

const TILE_W := 32
const TILE_H := 32
const MAP_COLS := 132
const MAP_ROWS := 102
const TILE_PATH := "res://assets/isometric tileset/isometric tileset/separated images/tile_%03d.png"

const TILES_DARK_SOIL := [12, 13, 14]
const TILES_MOSSY     := [20, 21, 22, 23]
const TILES_GREEN     := [34, 35, 36]
const TILES_BORDER    := [60, 61]
const TILES_ROCKY     := [60, 61]

const NEW_ASSETS := "res://assets/"

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

var _occupied := {}

func _ready() -> void:
	var noise_scatter := FastNoiseLite.new()
	noise_scatter.seed = 42
	noise_scatter.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_scatter.frequency = 0.18
	_generate_forest()
	_spawn_scatter(noise_scatter)
	modulate = Color(0.55, 0.70, 0.55, 1.0)

func _generate_forest() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.1

	for row in MAP_ROWS:
		for col in MAP_COLS:
			var is_border := (row == 0 or row == MAP_ROWS - 1
					or col == 0 or col == MAP_COLS - 1)

			var tile_index: int
			if is_border:
				tile_index = TILES_BORDER[_stable_pick(col + row * MAP_COLS, TILES_BORDER.size())]
			else:
				var n: float = noise.get_noise_2d(col, row)
				tile_index = _pick_forest_tile(n, col, row)

			_place_tile(col, row, tile_index)

func _pick_forest_tile(noise_val: float, col: int, row: int) -> int:
	var seed_val := col * 31 + row * 97
	if noise_val < -0.15:
		return TILES_DARK_SOIL[_stable_pick(seed_val, TILES_DARK_SOIL.size())]
	elif noise_val < 0.15:
		return TILES_MOSSY[_stable_pick(seed_val, TILES_MOSSY.size())]
	elif noise_val < 0.45:
		return TILES_GREEN[_stable_pick(seed_val, TILES_GREEN.size())]
	else:
		return TILES_ROCKY[_stable_pick(seed_val, TILES_ROCKY.size())]

func _stable_pick(seed_val: int, count: int) -> int:
	return abs(seed_val) % count

func _place_tile(col: int, row: int, tile_index: int) -> void:
	tile_index = clampi(tile_index, 0, 114)

	var sprite := Sprite2D.new()
	sprite.texture = load(TILE_PATH % tile_index)

	sprite.position = Vector2(
		(col - row) * TILE_W / 2.0,
		(col + row) * TILE_H / 4.0
	)
	sprite.z_index = -10
	add_child(sprite)

func _spawn_scatter(noise_scatter: FastNoiseLite) -> void:
	for row in MAP_ROWS:
		for col in MAP_COLS:
			if noise_scatter.get_noise_2d(col, row) < 0.25:
				continue

			if _occupied.has(Vector2i(col, row)):
				continue

			var is_border_zone := (row <= 3 or row >= MAP_ROWS - 4
					or col <= 3 or col >= MAP_COLS - 4)
			var is_edge_border := (row == 0 or row == MAP_ROWS - 1
					or col == 0 or col == MAP_COLS - 1)

			if is_edge_border:
				continue

			var seed_val := col * 31 + row * 97

			if is_border_zone:
				_try_place_border_object(col, row, seed_val)
			else:
				_try_place_interior_object(col, row, seed_val)

func _try_place_interior_object(col: int, row: int, seed_val: int) -> void:
	var idx: int = abs(seed_val) % INTERIOR_SCATTER.size()
	var e: Dictionary = INTERIOR_SCATTER[idx]
	_place_new_scatter(col, row, NEW_ASSETS + e["p"], e["z"], e["s"])

func _try_place_border_object(col: int, row: int, seed_val: int) -> void:
	var idx: int = abs(seed_val) % BORDER_SCATTER.size()
	var e: Dictionary = BORDER_SCATTER[idx]
	_place_new_scatter(col, row, NEW_ASSETS + e["p"], e["z"], e["s"])

func _place_new_scatter(col: int, row: int, path: String, z: int, s: float) -> void:
	if not ResourceLoader.exists(path):
		return
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = Vector2((col - row) * TILE_W / 2.0, (col + row) * TILE_H / 4.0)
	sprite.z_index = z
	sprite.scale = Vector2(s, s)
	add_child(sprite)
	_mark_occupied(col, row)

func _mark_occupied(col: int, row: int) -> void:
	for dc in [-1, 0, 1]:
		for dr in [-1, 0, 1]:
			_occupied[Vector2i(col + dc, row + dr)] = true
