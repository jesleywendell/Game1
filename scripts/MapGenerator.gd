extends Node2D

# Desolate land map generator
# Tiles are 32x32px arranged in isometric projection

const TILE_W := 32
const TILE_H := 32
const MAP_COLS := 28
const MAP_ROWS := 22
const TILE_PATH := "res://assets/isometric tileset/isometric tileset/separated images/tile_%03d.png"

# Tile indices for a desolate/wasteland feel.
# Adjust these constants if the chosen tiles don't match visually in the editor.
const TILES_GROUND   := [0, 1, 2, 3]       # base cracked earth
const TILES_DRY      := [4, 5, 6, 7]       # dry/arid variations
const TILES_ROCKY    := [8, 9, 10, 11]     # rocky patches
const TILES_DEAD     := [12, 13, 14]       # dead/burnt spots
const TILES_EDGE     := [20, 21, 22, 23]   # darker border tiles

func _ready() -> void:
	_generate_desolate_land()

func _generate_desolate_land() -> void:
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
				tile_index = TILES_EDGE[_stable_pick(col + row * MAP_COLS, TILES_EDGE.size())]
			else:
				var n: float = noise.get_noise_2d(col, row)  # -1.0 to 1.0
				tile_index = _pick_desolate_tile(n, col, row)

			_place_tile(col, row, tile_index)

func _pick_desolate_tile(noise_val: float, col: int, row: int) -> int:
	var seed_val := col * 31 + row * 97
	if noise_val < -0.25:
		return TILES_GROUND[_stable_pick(seed_val, TILES_GROUND.size())]
	elif noise_val < 0.05:
		return TILES_DRY[_stable_pick(seed_val, TILES_DRY.size())]
	elif noise_val < 0.3:
		return TILES_ROCKY[_stable_pick(seed_val, TILES_ROCKY.size())]
	else:
		return TILES_DEAD[_stable_pick(seed_val, TILES_DEAD.size())]

# Deterministic tile pick so the map looks the same every run
func _stable_pick(seed_val: int, count: int) -> int:
	return abs(seed_val) % count

func _place_tile(col: int, row: int, tile_index: int) -> void:
	# Clamp index to valid range (tile_000 to tile_114)
	tile_index = clampi(tile_index, 0, 114)

	var sprite := Sprite2D.new()
	sprite.texture = load(TILE_PATH % tile_index)

	# Isometric (2:1 diamond) screen position
	sprite.position = Vector2(
		(col - row) * TILE_W / 2.0,
		(col + row) * TILE_H / 4.0
	)
	sprite.z_index = -10
	add_child(sprite)
