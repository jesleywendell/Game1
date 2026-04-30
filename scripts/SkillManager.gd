extends Node

const DAMAGE_Q := 25.0
const DAMAGE_E := 20.0
const COOLDOWN_Q := 3.0
const COOLDOWN_E := 2.0
const ACTIVE_Q_DURATION := 0.3

const PROJECTILE_SCENE := preload("res://scenes/Projectile.tscn")

@onready var skill_area: Area2D = $"../SkillArea2D"
@onready var skill_area_shape: CollisionShape2D = $"../SkillArea2D/CollisionShape2D"

var cooldown_q_timer := 0.0
var cooldown_e_timer := 0.0
var skill_q_active_timer := 0.0
var skill_q_hit_targets: Array[Node] = []
var _player_ref: CharacterBody2D

# HUD-ready ratios: 0.0 = skill ready, 1.0 = just used
var cooldown_q_ratio: float:
	get: return clampf(cooldown_q_timer / COOLDOWN_Q, 0.0, 1.0)
var cooldown_e_ratio: float:
	get: return clampf(cooldown_e_timer / COOLDOWN_E, 0.0, 1.0)

func _ready() -> void:
	skill_area_shape.disabled = true

func _physics_process(delta: float) -> void:
	if skill_q_active_timer > 0.0:
		skill_q_active_timer -= delta
		if skill_q_active_timer <= 0.0:
			skill_area_shape.disabled = true
			if skill_area.body_entered.is_connected(_on_skill_q_body_entered):
				skill_area.body_entered.disconnect(_on_skill_q_body_entered)
			if skill_area.area_entered.is_connected(_on_skill_q_area_entered):
				skill_area.area_entered.disconnect(_on_skill_q_area_entered)
			cooldown_q_timer = COOLDOWN_Q

	if cooldown_q_timer > 0.0:
		cooldown_q_timer -= delta

	if cooldown_e_timer > 0.0:
		cooldown_e_timer -= delta

func use_q(player: CharacterBody2D) -> void:
	if cooldown_q_timer > 0.0 or skill_q_active_timer > 0.0:
		return
	player.drain_hp(5.0)
	AudioManager.play_sfx("skill_q")
	AudioManager.play_sfx("hp_drain")
	_player_ref = player
	skill_q_hit_targets.clear()
	skill_area_shape.disabled = false
	skill_area.body_entered.connect(_on_skill_q_body_entered)
	skill_area.area_entered.connect(_on_skill_q_area_entered)
	skill_q_active_timer = ACTIVE_Q_DURATION

func use_e(player: CharacterBody2D, mouse_pos: Vector2) -> void:
	if cooldown_e_timer > 0.0:
		return
	player.drain_hp(3.0)
	AudioManager.play_sfx("skill_e")
	AudioManager.play_sfx("hp_drain")
	var projectile: Area2D = PROJECTILE_SCENE.instantiate()
	projectile.global_position = player.global_position
	var dir := (mouse_pos - player.global_position)
	projectile.direction = dir.normalized() if dir.length_squared() > 0.0 else Vector2.RIGHT
	projectile.source = player
	projectile.damage = DAMAGE_E + ProgressionManager.get_skill_damage_bonus()
	get_tree().current_scene.add_child(projectile)
	cooldown_e_timer = COOLDOWN_E

func _on_skill_q_body_entered(body: Node) -> void:
	_apply_q_hit(body)

func _on_skill_q_area_entered(area: Area2D) -> void:
	_apply_q_hit(area)

func _apply_q_hit(target: Node) -> void:
	if target == _player_ref:
		return
	if skill_q_hit_targets.has(target):
		return
	skill_q_hit_targets.append(target)
	var dir := Vector2.ZERO
	if _player_ref:
		dir = (target.global_position - _player_ref.global_position).normalized()
	var dmg := DAMAGE_Q + ProgressionManager.get_skill_damage_bonus()
	if target.has_method("take_damage"):
		target.take_damage(dmg, dir)
	elif target.has_method("receive_hit"):
		target.receive_hit(dmg, dir)
