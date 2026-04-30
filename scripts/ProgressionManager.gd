extends Node

const SAVE_PATH   := "user://player_data.tres"
const BASE_XP     := 100.0
const XP_EXPONENT := 1.5

const ATTACK_DMG_BONUS := 5.0
const SKILL_DMG_BONUS  := 8.0
const SPEED_BONUS      := 15.0
const MAX_HEALTH_BONUS := 20.0

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
		data.skill_points += 1
		required = xp_required(data.level)
		leveled_up.emit(data.level)
	xp_changed.emit(data.current_xp, xp_required(data.level))
	save()

func apply_upgrade(attribute: String) -> void:
	if data.skill_points <= 0:
		return
	match attribute:
		"attack_damage": data.attack_damage_upgrades += 1
		"skill_damage":  data.skill_damage_upgrades  += 1
		"speed":         data.speed_upgrades         += 1
		"max_health":    data.max_health_upgrades    += 1
	data.skill_points -= 1
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

const HUB_UPGRADE_COSTS := {"attack_damage": 15, "max_health": 12, "dash_cd": 20}
const HUB_UPGRADE_MAX   := 5

func buy_hub_upgrade(attribute: String) -> bool:
	if not HUB_UPGRADE_COSTS.has(attribute):
		return false
	if _get_upgrade_count(attribute) >= HUB_UPGRADE_MAX:
		return false
	if not spend_fragments(HUB_UPGRADE_COSTS[attribute]):
		return false
	match attribute:
		"attack_damage": data.attack_damage_upgrades += 1
		"max_health":    data.max_health_upgrades    += 1
		"dash_cd":       data.dash_cd_upgrades       += 1
	save()
	upgrade_applied.emit()
	return true

func get_dash_cd_reduction() -> float:
	return data.dash_cd_upgrades * 0.1

func get_hub_upgrade_count(attribute: String) -> int:
	return _get_upgrade_count(attribute)

func _get_upgrade_count(attribute: String) -> int:
	match attribute:
		"attack_damage": return data.attack_damage_upgrades
		"max_health":    return data.max_health_upgrades
		"dash_cd":       return data.dash_cd_upgrades
	return 0

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
