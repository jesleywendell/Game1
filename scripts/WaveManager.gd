extends Node

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)

const BOAR_SCENE   := preload("res://scenes/Boar.tscn")
const KNIGHT_SCENE := preload("res://scenes/KnightCoxinha.tscn")
const BASE_COUNT := 4
const DIFFICULTY_CURVE := 1.18
const BASE_HEALTH := 60.0
const BASE_DAMAGE := 10.0

const SPAWN_COORDS := [
	Vector2i(8, 8),   Vector2i(35, 8),
	Vector2i(8, 25),  Vector2i(35, 25),
	Vector2i(14, 10), Vector2i(29, 10),
	Vector2i(10, 18), Vector2i(33, 18),
	Vector2i(12, 26), Vector2i(30, 26),
	Vector2i(20, 7),  Vector2i(22, 28),
	Vector2i(7, 14),  Vector2i(36, 20),
	Vector2i(16, 6),  Vector2i(27, 27),
]

var current_wave := 0
var _alive_count := 0
var _world: Node2D

func init(world: Node2D) -> void:
	_world = world

func start_next_wave() -> void:
	current_wave += 1
	var count := int(BASE_COUNT * pow(DIFFICULTY_CURVE, current_wave - 1))
	var multiplier := pow(DIFFICULTY_CURVE, current_wave - 1)
	_alive_count = count
	wave_started.emit(current_wave)
	for i in count:
		if current_wave >= 2 and i % 3 == 2:
			_spawn_knight(i, multiplier)
		else:
			_spawn_boar(i, multiplier)

func _spawn_boar(index: int, multiplier: float) -> void:
	var boar = BOAR_SCENE.instantiate()
	var coord: Vector2i = SPAWN_COORDS[index % SPAWN_COORDS.size()]
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
	var coord: Vector2i = SPAWN_COORDS[index % SPAWN_COORDS.size()]
	var offset := Vector2(randf_range(-20.0, 20.0), randf_range(-10.0, 10.0))
	knight.position = Vector2((coord.x - coord.y) * 16.0, (coord.x + coord.y) * 8.0) + offset
	knight.MAX_HEALTH = 150.0 * multiplier
	knight.current_health = knight.MAX_HEALTH
	knight.DAMAGE = 20.0 * multiplier
	knight.xp_reward = 65.0 * multiplier
	knight.add_to_group("active_enemies")
	knight.tree_exited.connect(_on_enemy_died)
	_world.add_child(knight)

func _on_enemy_died() -> void:
	call_deferred("_check_wave_clear")

func _check_wave_clear() -> void:
	if not is_inside_tree():
		return
	var alive := get_tree().get_nodes_in_group("active_enemies").size()
	if alive == 0:
		wave_cleared.emit(current_wave)
