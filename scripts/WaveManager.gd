extends Node

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal area_cleared()
signal boss_spawned()
signal boss_intro_requested(area: int)
signal enemy_killed()
signal timer_tick(remaining: float)
signal frenzy_started()

const BOAR_SCENE   := preload("res://scenes/Boar.tscn")
const KNIGHT_SCENE := preload("res://scenes/KnightCoxinha.tscn")
const SKELETON_SCRIPT   := preload("res://scripts/Skeleton.gd")
const GALINHA_SCRIPT    := preload("res://scripts/GalinhaPodre.gd")
const TRISS_SCRIPT      := preload("res://scripts/Triss.gd")
const LEJYES_SCRIPT     := preload("res://scripts/LeyjesMosca.gd")
const BASE_COUNT := 4
const DIFFICULTY_CURVE := 1.18
const BASE_HEALTH := 60.0
const BASE_DAMAGE := 10.0

const ARENA_TOTAL := 3
const ARENA_DURATION := 90.0

const SPAWN_COORDS := [
	Vector2i(50, 30), Vector2i(40, 40),
	Vector2i(45, 35), Vector2i(60, 20),
	Vector2i(80, 80), Vector2i(90, 70),
	Vector2i(75, 85), Vector2i(85, 75),
	Vector2i(40, 80), Vector2i(35, 80),
	Vector2i(40, 85), Vector2i(35, 85),
	Vector2i(80, 40), Vector2i(85, 40),
	Vector2i(80, 35), Vector2i(85, 35),
]

var current_wave := 0
var _alive_count := 0
var _boss_alive := false
var _arena_timer    := ARENA_DURATION
var _combat_active  := false
var _frenzy_active       := false
var _chicken_boss_active := false
var _saved_wave          := 0
var _saved_alive_count   := 0
var _world: Node2D

func init(world: Node2D) -> void:
	_world = world

func start_next_wave() -> void:
	_arena_timer   = ARENA_DURATION
	_frenzy_active = false
	_combat_active = true
	current_wave += 1
	var area        := ProgressionManager.get_current_area()
	var area_scale  := 1.0 + (area - 1) * 0.6
	var base        := BASE_COUNT + (area - 1) * 4
	var count       := int(base * pow(DIFFICULTY_CURVE, current_wave - 1))
	var multiplier  := pow(DIFFICULTY_CURVE, current_wave - 1) * area_scale
	_alive_count = count
	wave_started.emit(current_wave)
	for i in count:
		var is_galinha := false
		if area >= 3:
			# Fase 3: galinha → galinha → skeleton
			is_galinha = i % 3 != 2
		elif area >= 2:
			# Fase 2: galinha a cada 2, skeleton nos demais
			is_galinha = i % 2 == 1 or (current_wave >= 2 and i % 4 == 3)
		else:
			# Fase 1: galinha na wave 2+, skeleton nos demais
			is_galinha = not is_galinha and current_wave >= 2 and i % 4 == 3
		if is_galinha:
			_spawn_galinha(i, multiplier)
		else:
			_spawn_skeleton(i, multiplier)

func _spawn_boar(index: int, multiplier: float) -> void:
	var boar = BOAR_SCENE.instantiate()
	var coord: Vector2i = SPAWN_COORDS[randi() % SPAWN_COORDS.size()]
	var offset := Vector2(randf_range(-20.0, 20.0), randf_range(-10.0, 10.0))
	boar.position = Vector2((coord.x - coord.y) * 16.0, (coord.x + coord.y) * 8.0) + offset
	boar.MAX_HEALTH = BASE_HEALTH * multiplier
	boar.current_health = boar.MAX_HEALTH
	boar.DAMAGE = BASE_DAMAGE * multiplier
	boar.xp_reward = 25.0 * multiplier
	boar.add_to_group("active_enemies")
	boar.tree_exited.connect(_on_enemy_died)
	_world.add_child(boar)

func _spawn_knight(index: int, multiplier: float) -> void:
	var knight = KNIGHT_SCENE.instantiate()
	var coord: Vector2i = SPAWN_COORDS[randi() % SPAWN_COORDS.size()]
	var offset := Vector2(randf_range(-20.0, 20.0), randf_range(-10.0, 10.0))
	knight.position = Vector2((coord.x - coord.y) * 16.0, (coord.x + coord.y) * 8.0) + offset
	knight.MAX_HEALTH = 150.0 * multiplier
	knight.current_health = knight.MAX_HEALTH
	knight.DAMAGE = 20.0 * multiplier
	knight.xp_reward = 65.0 * multiplier
	knight.add_to_group("active_enemies")
	knight.tree_exited.connect(_on_enemy_died)
	_world.add_child(knight)

func _spawn_skeleton(index: int, multiplier: float) -> void:
	var skeleton = SKELETON_SCRIPT.new()
	var coord: Vector2i = SPAWN_COORDS[randi() % SPAWN_COORDS.size()]
	var offset := Vector2(randf_range(-20.0, 20.0), randf_range(-10.0, 10.0))
	skeleton.position = Vector2((coord.x - coord.y) * 16.0, (coord.x + coord.y) * 8.0) + offset
	skeleton.MAX_HEALTH = 30.0 * multiplier
	skeleton.current_health = skeleton.MAX_HEALTH
	skeleton.DAMAGE = 10.0 * multiplier
	skeleton.xp_reward = 20.0 * multiplier
	skeleton.add_to_group("active_enemies")
	skeleton.tree_exited.connect(_on_enemy_died)
	_world.add_child(skeleton)

func _spawn_galinha(index: int, multiplier: float) -> void:
	var galinha = GALINHA_SCRIPT.new()
	var coord: Vector2i = SPAWN_COORDS[randi() % SPAWN_COORDS.size()]
	var offset := Vector2(randf_range(-20.0, 20.0), randf_range(-10.0, 10.0))
	galinha.position = Vector2((coord.x - coord.y) * 16.0, (coord.x + coord.y) * 8.0) + offset
	galinha.MAX_HEALTH = 20.0 * multiplier
	galinha.current_health = galinha.MAX_HEALTH
	galinha.DAMAGE = 8.0 * multiplier
	galinha.xp_reward = 15.0 * multiplier
	galinha.add_to_group("active_enemies")
	galinha.tree_exited.connect(_on_enemy_died)
	_world.add_child(galinha)

func _on_enemy_died() -> void:
	enemy_killed.emit()
	call_deferred("_check_wave_clear")

func _check_wave_clear() -> void:
	if not is_inside_tree():
		return
	if _chicken_boss_active:
		return
	var alive := get_tree().get_nodes_in_group("active_enemies").size()
	if alive > 0:
		return
	if _boss_alive:
		return
	_combat_active = false
	if current_wave >= ARENA_TOTAL:
		_boss_alive = true
		await get_tree().create_timer(0.8).timeout
		boss_intro_requested.emit(ProgressionManager.get_current_area())
	else:
		wave_cleared.emit(current_wave)

func execute_boss_spawn() -> void:
	_do_spawn_boss()

func _do_spawn_boss() -> void:
	var area       := ProgressionManager.get_current_area()
	var area_scale := 1.0 + (area - 1) * 0.5
	var boss: Node
	if area >= 3:
		boss = LEJYES_SCRIPT.new()
		boss.MAX_HEALTH = 450.0 * area_scale
		boss.DAMAGE     = 40.0 * area_scale
		boss.xp_reward  = 250.0 * area_scale
	elif area >= 2:
		boss = TRISS_SCRIPT.new()
		boss.MAX_HEALTH = 280.0 * area_scale
		boss.DAMAGE     = 28.0 * area_scale
		boss.xp_reward  = 150.0 * area_scale
	else:
		boss = KNIGHT_SCENE.instantiate()
		boss.MAX_HEALTH = 250.0 * area_scale
		boss.DAMAGE     = 30.0 * area_scale
		boss.xp_reward  = 200.0 * area_scale
	boss.current_health = boss.MAX_HEALTH
	boss.position       = Vector2(0.0, 800.0)
	boss.is_boss        = true
	boss.add_to_group("active_enemies")
	boss.tree_exited.connect(_on_boss_died)
	_world.add_child(boss)
	boss_spawned.emit()

func _process(delta: float) -> void:
	if not _combat_active or _frenzy_active or _boss_alive or _chicken_boss_active:
		return
	_arena_timer -= delta
	timer_tick.emit(maxf(_arena_timer, 0.0))
	if _arena_timer <= 0.0:
		_trigger_frenzy()

func _trigger_frenzy() -> void:
	_frenzy_active = true
	frenzy_started.emit()
	for enemy in get_tree().get_nodes_in_group("active_enemies"):
		if enemy.has_method("apply_frenzy"):
			enemy.apply_frenzy()

func debug_skip_to_wave(target_wave: int) -> void:
	for enemy in get_tree().get_nodes_in_group("active_enemies"):
		enemy.queue_free()
	_combat_active = false
	_frenzy_active = false
	_boss_alive = false
	current_wave = target_wave - 1
	start_next_wave()

func _on_boss_died() -> void:
	_boss_alive = false
	var player := get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if player == null or player.is_dead:
		return
	area_cleared.emit()

func suspend_for_chicken_boss() -> void:
	_saved_wave        = current_wave
	_saved_alive_count = get_tree().get_nodes_in_group("active_enemies").size()
	_chicken_boss_active = true
	_combat_active       = false
	for enemy in get_tree().get_nodes_in_group("active_enemies"):
		enemy.queue_free()

func resume_after_chicken_boss() -> void:
	_chicken_boss_active = false
	if _saved_alive_count == 0:
		wave_cleared.emit(_saved_wave)
		return
	var multiplier := pow(DIFFICULTY_CURVE, _saved_wave - 1)
	for i in _saved_alive_count:
		var is_galinha := _saved_wave >= 2 and i % 4 == 3
		if is_galinha:
			_spawn_galinha(i, multiplier)
		else:
			_spawn_skeleton(i, multiplier)
	if _frenzy_active:
		for enemy in get_tree().get_nodes_in_group("active_enemies"):
			if enemy.has_method("apply_frenzy"):
				enemy.apply_frenzy()
	_alive_count   = _saved_alive_count
	_combat_active = true
