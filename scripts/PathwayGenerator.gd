extends Node2D

# Mesmas constantes do MapGenerator para compatibilidade visual
const TILE_PATH := "res://assets/isometric tileset/isometric tileset/separated images/tile_%03d.png"

const SCATTER_BASE: Dictionary = {
	1: "res://assets/forest/",
	2: "res://assets/Free-Cursed-Land-Top-Down-Pixel-Art-Tileset/PNG/Objects_separetely/",
	3: "res://assets/Free-Undead-Tileset-Top-Down-Pixel-Art/PNG/Objects_separately/",
}

# Subsets dos arrays do MapGenerator — mesmos nomes de arquivo
const SCATTER_FILES: Dictionary = {
	1: [
		"Rock_shadow1_1.png", "Rock_shadow1_2.png", "Rock_shadow1_3.png",
		"Plant_shadow1_1.png", "Plant_shadow1_2.png", "Plant_shadow1_3.png",
		"Dead_tree_shadow1_1.png", "Dead_tree_shadow1_2.png",
		"Thorn_palnt_shadow2_1.png", "Thorn_palnt_shadow2_2.png",
		"Bones_shadow1_1.png", "Bones_shadow1_5.png", "Bones_shadow1_8.png",
	],
	2: [
		"Rock1_shadow1_1.png", "Rock1_shadow1_2.png", "Rock1_shadow1_3.png",
		"Rock2_shadow2_1.png", "Rock2_shadow2_2.png",
		"Rock_eyes_shadow1_1.png", "Rock_eyes_shadow1_2.png",
		"Bones_shadow1_1.png", "Bones_shadow1_2.png", "Bones_shadow2_1.png",
		"Pustules_shadow1_1.png", "Pustules_shadow1_2.png",
		"Fetus_shadow1_1.png", "Many_eyes_plant_shadow1_1.png",
	],
	3: [
		"Grave_shadow1_1.png", "Grave_shadow1_4.png", "Grave_shadow1_7.png",
		"Grave_shadow1_11.png",
		"Bones_shadow1_1.png", "Bones_shadow1_3.png", "Bones_shadow1_8.png",
		"Bones_shadow2_1.png", "Bones_shadow2_4.png",
		"Crystal_shadow1_1.png", "Crystal_shadow1_2.png",
		"Dead_arm_shadow1_1.png", "Dead_arm_shadow2_1.png",
		"Rock_shadow1_1.png", "Pile_sculls_shadow1.png",
	],
}

# Tiles de chao por area (indices do tileset isometrico)
const FLOOR_TILES: Dictionary = {
	1: [12, 13, 14, 20, 21, 22],
	2: [20, 21, 22, 23, 60, 61],
	3: [60, 61, 12, 13, 14],
}

# Cor das particulas do gateway por area
const GATEWAY_COLOR: Dictionary = {
	1: Color(0.25, 0.90, 0.20, 0.90),
	2: Color(0.70, 0.10, 0.95, 0.90),
	3: Color(0.30, 0.50, 0.95, 0.90),
}

const CORRIDOR_STEPS   := 20      # passos ao longo do corredor
const STEP_DIST        := 40.0    # pixels entre cada passo
const CROSS_TILES      := 5       # tiles de largura (impar)
const CROSS_DIST       := 18.0    # pixels entre tiles transversais
const WALL_OFFSET      := 58.0    # distancia do eixo ao muro de colisao
const PROP_OFFSET      := 52.0    # distancia do eixo ao prop lateral
const PROP_SCALE_BASE  := 0.38    # igual ao MapGenerator s_interior

# Diracao isometrica "sudeste" (col++): Vector2(16,8).normalized()
const DIR  := Vector2(0.8944, 0.4472)
const PERP := Vector2(-0.4472, 0.8944)

var portal_end:   Vector2
var _end_wall_cs: CollisionShape2D
var _tex_cache:   Dictionary = {}

# ─── Ponto de entrada ────────────────────────────────────────────────────────

func build(from_area: int, to_area: int, origin: Vector2) -> void:
	var from_tiles:  Array  = FLOOR_TILES.get(from_area, FLOOR_TILES[1])
	var to_tiles:    Array  = FLOOR_TILES.get(to_area,   FLOOR_TILES.get(to_area, FLOOR_TILES[2]))
	var from_files:  Array  = SCATTER_FILES.get(from_area, [])
	var to_files:    Array  = SCATTER_FILES.get(to_area,   [])
	var from_base:   String = SCATTER_BASE.get(from_area, SCATTER_BASE[1])
	var to_base:     String = SCATTER_BASE.get(to_area,   SCATTER_BASE[2])

	for step in CORRIDOR_STEPS:
		var t      := float(step) / float(CORRIDOR_STEPS - 1)
		var center := origin + DIR * step * STEP_DIST
		var tiles  := from_tiles if t < 0.5 else to_tiles
		var files  := from_files if t < 0.5 else to_files
		var base   := from_base  if t < 0.5 else to_base
		var sv     := step * 131  # semente deterministica variada

		_lay_floor_strip(center, tiles, sv)

		# Props laterais em passos alternados
		if step % 2 == 0 and not files.is_empty():
			_place_prop(center + PERP * PROP_OFFSET, files, base, sv)
			_place_prop(center - PERP * PROP_OFFSET, files, base, sv + 67)

	_add_walls(origin)
	_spawn_gateway(origin, from_area)
	# Portal fica no centro da praca — 2 passos alem do fim do corredor
	portal_end = origin + DIR * (CORRIDOR_STEPS + 2) * STEP_DIST
	_add_plaza_floor(portal_end, from_tiles, to_tiles)

# ─── Chao do corredor ────────────────────────────────────────────────────────

func _lay_floor_strip(center: Vector2, tiles: Array, sv: int) -> void:
	for ci in CROSS_TILES:
		var offset   := (ci - CROSS_TILES / 2) * CROSS_DIST
		var tile_pos := center + PERP * offset
		var tile_idx: int = tiles[abs(sv + ci) % tiles.size()]
		_place_floor(tile_pos, tile_idx)

func _place_floor(world_pos: Vector2, tile_idx: int) -> void:
	var path := TILE_PATH % clampi(tile_idx, 0, 114)
	var spr := Sprite2D.new()
	spr.texture        = _get_tex(path)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.z_index        = -9   # logo acima do chao existente (-10)
	add_child(spr)
	spr.global_position = world_pos

# ─── Props laterais ──────────────────────────────────────────────────────────

func _place_prop(world_pos: Vector2, files: Array, base: String, sv: int) -> void:
	var file: String = files[abs(sv) % files.size()]
	var path: String = base + file
	if not ResourceLoader.exists(path):
		return
	var scale_mul := 0.82 + 0.36 * float(abs(sv * 7 + 31) % 100) / 100.0
	var spr := Sprite2D.new()
	spr.texture        = _get_tex(path)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.scale          = Vector2(PROP_SCALE_BASE * scale_mul, PROP_SCALE_BASE * scale_mul)
	spr.z_index        = -2
	add_child(spr)
	spr.global_position = world_pos

# ─── Praca ao redor do portal ────────────────────────────────────────────────

func _add_plaza_floor(center: Vector2, from_tiles: Array, to_tiles: Array) -> void:
	var plaza_r := 3
	for ps in range(-plaza_r, plaza_r + 1):
		for pc in range(-(CROSS_TILES + 2), (CROSS_TILES + 3)):
			var sv      := ps * 100 + pc * 7
			var t       := float(ps + plaza_r) / float(plaza_r * 2)
			var tiles   := from_tiles if t < 0.5 else to_tiles
			var tile_idx: int = tiles[abs(sv) % tiles.size()]
			var tpos    := center + DIR * ps * STEP_DIST + PERP * pc * CROSS_DIST
			_place_floor(tpos, tile_idx)

# ─── Muros de colisao ────────────────────────────────────────────────────────

func _add_walls(origin: Vector2) -> void:
	var corridor_end := origin + DIR * CORRIDOR_STEPS * STEP_DIST
	# Paredes laterais se extendem ate o fim da praca (4 passos alem do corredor)
	var plaza_end    := origin + DIR * (CORRIDOR_STEPS + 4) * STEP_DIST

	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask  = 0
	add_child(body)

	# Paredes laterais — cobrem corredor + praca
	for side in [-1, 1]:
		var offset_v: Vector2 = PERP * (WALL_OFFSET * float(side))
		var seg := SegmentShape2D.new()
		seg.a = origin    + offset_v
		seg.b = plaza_end + offset_v
		var cs := CollisionShape2D.new()
		cs.shape = seg
		body.add_child(cs)

	# Muro de fim de corredor — bloqueia ate o portal surgir (sera desativado)
	var end_seg := SegmentShape2D.new()
	end_seg.a = corridor_end + PERP * WALL_OFFSET
	end_seg.b = corridor_end - PERP * WALL_OFFSET
	_end_wall_cs = CollisionShape2D.new()
	_end_wall_cs.shape = end_seg
	body.add_child(_end_wall_cs)

	# Muro permanente no final da praca — impede sair pelo fundo
	var close_seg := SegmentShape2D.new()
	close_seg.a = plaza_end + PERP * WALL_OFFSET
	close_seg.b = plaza_end - PERP * WALL_OFFSET
	var close_cs := CollisionShape2D.new()
	close_cs.shape = close_seg
	body.add_child(close_cs)

func open_end() -> void:
	if is_instance_valid(_end_wall_cs):
		_end_wall_cs.set_deferred("disabled", true)

# ─── Marcador de entrada ─────────────────────────────────────────────────────

func _spawn_gateway(world_pos: Vector2, from_area: int) -> void:
	var col: Color = GATEWAY_COLOR.get(from_area, Color(1.0, 0.7, 0.0, 0.9))
	var p                    := CPUParticles2D.new()
	p.emitting                = true
	p.amount                  = 32
	p.lifetime                = 2.5
	p.emission_shape          = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius  = 28.0
	p.direction               = Vector2(0.0, -1.0)
	p.spread                  = 65.0
	p.gravity                 = Vector2(0.0, -22.0)
	p.initial_velocity_min    = 12.0
	p.initial_velocity_max    = 38.0
	p.color                   = col
	p.z_index                 = 15
	add_child(p)
	p.global_position = world_pos

# ─── Cache de texturas ────────────────────────────────────────────────────────

func _get_tex(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path)
	return _tex_cache[path]
