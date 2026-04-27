extends Node2D

# Corrupted rotten forest map generator
# Tiles are 32x32px arranged in isometric projection

const TILE_W := 32
const TILE_H := 32
const MAP_COLS := 44
const MAP_ROWS := 34
const TILE_PATH := "res://assets/isometric tileset/isometric tileset/separated images/tile_%03d.png"

const OBJECTS_PATH := "res://assets/forest/"

const TILES_DARK_SOIL := [12, 13, 14]
const TILES_MOSSY     := [20, 21, 22, 23]
const TILES_GREEN     := [34, 35, 36]
const TILES_BORDER    := [60, 61]
const TILES_ROCKY     := [60, 61]

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
	var r: int = abs(seed_val * 7 + 13) % 100

	if r < 7:
		_place_object(col, row, "Bones_shadow1", 18, -8, 1.0)
	elif r < 12:
		_place_object(col, row, "Plant_shadow1", 5, -8, 1.0)
	elif r < 15:
		_place_object(col, row, "Broken_tree_shadow1", 7, -2, 1.3)
	elif r < 17:
		_place_object(col, row, "Rock_shadow1", 5, -5, 1.2)
	elif r < 19:
		_place_object(col, row, "Thorn_palnt_shadow2", 5, -8, 1.0)
	elif r < 23:
		_place_tile_as_prop(col, row, 45, -6)
	elif r < 25:
		_place_tile_as_prop(col, row, 65, -5)
	elif r < 26:
		_place_tile_as_prop(col, row, 75, -9)

func _try_place_border_object(col: int, row: int, seed_val: int) -> void:
	var r: int = abs(seed_val * 7 + 13) % 100

	if r < 20:
		_place_object(col, row, "Dead_tree_shadow1", 3, -2, 1.3)
	elif r < 32:
		_place_object(col, row, "Broken_tree_shadow1", 7, -2, 1.3)

func _place_object(col: int, row: int, prefix: String, max_n: int, z: int, obj_scale: float) -> void:
	var n: int = (abs(col * 31 + row * 97) % max_n) + 1
	var filename := "%s_%d.png" % [prefix, n]
	var full_path := OBJECTS_PATH + filename

	var sprite := Sprite2D.new()
	sprite.texture = load(full_path)
	sprite.position = Vector2(
		(col - row) * TILE_W / 2.0,
		(col + row) * TILE_H / 4.0
	)
	sprite.z_index = z
	sprite.scale = Vector2(obj_scale, obj_scale)
	add_child(sprite)
	_mark_occupied(col, row)

func _mark_occupied(col: int, row: int) -> void:
	for dc in [-1, 0, 1]:
		for dr in [-1, 0, 1]:
			_occupied[Vector2i(col + dc, row + dr)] = true

func _place_tile_as_prop(col: int, row: int, tile_index: int, z: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(TILE_PATH % tile_index)
	sprite.position = Vector2(
		(col - row) * TILE_W / 2.0,
		(col + row) * TILE_H / 4.0
	)
	sprite.z_index = z
	_mark_occupied(col, row)
	add_child(sprite)
