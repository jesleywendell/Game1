extends Node

const SAVE_PATH   := "user://player_data.tres"
const BASE_XP     := 100.0
const XP_EXPONENT := 1.5

const ATTACK_DMG_BONUS := 5.0
const SKILL_DMG_BONUS  := 8.0
const SPEED_BONUS      := 15.0
const MAX_HEALTH_BONUS := 20.0

# custo(n) = base + escala * n^2  onde n = upgrades ja comprados daquele tipo
const UPGRADE_BASE := {
	"attack_damage": 5,
	"skill_damage":  7,
	"speed":         4,
	"max_health":    3,
}
const UPGRADE_SCALE := {
	"attack_damage": 3,
	"skill_damage":  4,
	"speed":         2,
	"max_health":    2,
}

signal xp_changed(current: float, required: float)
signal leveled_up(new_level: int)
signal upgrade_applied
signal fragments_changed(total: int)

var data: PlayerData

func _ready() -> void:
	_load()

func _load() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		data = ResourceLoader.load(SAVE_PATH) as PlayerData
	if data == null:
		data = PlayerData.new()

func save() -> void:
	ResourceSaver.save(data, SAVE_PATH)

func reset() -> void:
	data = PlayerData.new()
	save()

func xp_required(level: int) -> float:
	return BASE_XP * pow(level, XP_EXPONENT)

func add_xp(amount: float) -> void:
	data.current_xp += amount
	var required := xp_required(data.level)
	while data.current_xp >= required:
		data.current_xp -= required
		data.level += 1
		required = xp_required(data.level)
		leveled_up.emit(data.level)
	xp_changed.emit(data.current_xp, xp_required(data.level))
	save()

func get_upgrade_count(attribute: String) -> int:
	match attribute:
		"attack_damage": return data.attack_damage_upgrades
		"skill_damage":  return data.skill_damage_upgrades
		"speed":         return data.speed_upgrades
		"max_health":    return data.max_health_upgrades
	return 0

func get_upgrade_cost(attribute: String) -> int:
	var n := get_upgrade_count(attribute)
	return UPGRADE_BASE[attribute] + UPGRADE_SCALE[attribute] * n * n

func apply_upgrade(attribute: String) -> void:
	var cost := get_upgrade_cost(attribute)
	if not spend_fragments(cost):
		return
	match attribute:
		"attack_damage": data.attack_damage_upgrades += 1
		"skill_damage":  data.skill_damage_upgrades  += 1
		"speed":         data.speed_upgrades         += 1
		"max_health":    data.max_health_upgrades    += 1
	upgrade_applied.emit()
	save()

func get_attack_damage(base: float) -> float:
	return base + data.attack_damage_upgrades * ATTACK_DMG_BONUS

func get_skill_damage_bonus() -> float:
	return data.skill_damage_upgrades * SKILL_DMG_BONUS

func get_speed(base: float) -> float:
	return base + data.speed_upgrades * SPEED_BONUS

func get_max_health(base: float) -> float:
	return base + data.max_health_upgrades * MAX_HEALTH_BONUS

func add_fragments(amount: int) -> void:
	data.soul_fragments += amount
	save()
	fragments_changed.emit(data.soul_fragments)

func spend_fragments(amount: int) -> bool:
	if data.soul_fragments < amount:
		return false
	data.soul_fragments -= amount
	save()
	fragments_changed.emit(data.soul_fragments)
	return true

func get_fragments() -> int:
	return data.soul_fragments

func get_current_area() -> int:
	return data.current_area

func advance_area() -> void:
	data.current_area += 1
	save()

func reset_level() -> void:
	data.level = 1
	data.current_xp = 0.0
	data.attack_damage_upgrades = 0
	data.skill_damage_upgrades = 0
	data.speed_upgrades = 0
	data.max_health_upgrades = 0
	save()
	xp_changed.emit(data.current_xp, xp_required(data.level))
