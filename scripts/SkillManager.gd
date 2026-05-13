extends Node

const DAMAGE_Q      := 25.0
const DAMAGE_E      := 20.0
const COOLDOWN_Q    := 4.0
const COOLDOWN_E    := 2.0
const ACTIVE_Q_DURATION := 2.0
const HIT_INTERVAL    := 0.5   # segundos entre cada tick de dano da Q
const HIT_AREA_RADIUS := 90.0
const PUSH_RADIUS     := 55.0  # coincide com ORBIT_RADIUS em SkillVFX_Q

const PROJECTILE_SCENE := preload("res://scenes/Projectile.tscn")
const VFX_Q_SCRIPT     := preload("res://scripts/SkillVFX_Q.gd")

@onready var skill_area: Area2D = $"../SkillArea2D"
@onready var skill_area_shape: CollisionShape2D = $"../SkillArea2D/CollisionShape2D"

var cooldown_q_timer := 0.0
var cooldown_e_timer := 0.0
var skill_q_active_timer := 0.0
var _q_hit_cooldown := 0.0
var _player_ref: CharacterBody2D
var _vfx_q: Node2D = null

var cooldown_q_ratio: float:
	get: return clampf(cooldown_q_timer / COOLDOWN_Q, 0.0, 1.0)
var cooldown_e_ratio: float:
	get: return clampf(cooldown_e_timer / COOLDOWN_E, 0.0, 1.0)

func _ready() -> void:
	skill_area_shape.disabled = true
	var shape := skill_area_shape.shape
	if shape is CircleShape2D:
		(shape as CircleShape2D).radius = HIT_AREA_RADIUS
	elif shape is RectangleShape2D:
		(shape as RectangleShape2D).size = Vector2(HIT_AREA_RADIUS * 2.0, HIT_AREA_RADIUS * 2.0)

func _physics_process(delta: float) -> void:
	if skill_q_active_timer > 0.0:
		skill_q_active_timer -= delta

		if is_instance_valid(_vfx_q) and _player_ref:
			_vfx_q.global_position = _player_ref.global_position

		_q_hit_cooldown -= delta
		if _q_hit_cooldown <= 0.0:
			_q_hit_cooldown = HIT_INTERVAL
			for body in skill_area.get_overlapping_bodies():
				_apply_q_hit(body)
			for area in skill_area.get_overlapping_areas():
				_apply_q_hit(area)

		_push_enemies_out()

		if skill_q_active_timer <= 0.0:
			skill_area_shape.disabled = true
			cooldown_q_timer = COOLDOWN_Q
			AudioManager.stop_skill_q_sound()
			if is_instance_valid(_vfx_q):
				_vfx_q.finish()
				_vfx_q = null

	if cooldown_q_timer > 0.0:
		cooldown_q_timer -= delta
	if cooldown_e_timer > 0.0:
		cooldown_e_timer -= delta

func use_q(player: CharacterBody2D) -> void:
	if cooldown_q_timer > 0.0 or skill_q_active_timer > 0.0:
		return
	player.drain_hp(5.0)
	AudioManager.play_sfx("hp_drain")
	_player_ref = player
	skill_area_shape.disabled = false
	skill_q_active_timer = ACTIVE_Q_DURATION
	_q_hit_cooldown = 0.0
	AudioManager.play_skill_q_sound()

	var vfx := VFX_Q_SCRIPT.new()
	vfx.global_position = player.global_position
	get_tree().current_scene.add_child(vfx)
	_vfx_q = vfx

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

func _push_enemies_out() -> void:
	if not _player_ref or not is_inside_tree():
		return
	for enemy in get_tree().get_nodes_in_group("active_enemies"):
		if not is_instance_valid(enemy):
			continue
		var to_enemy: Vector2 = enemy.global_position - _player_ref.global_position
		var dist := to_enemy.length()
		if dist < PUSH_RADIUS and dist > 1.0:
			enemy.global_position = _player_ref.global_position + to_enemy.normalized() * (PUSH_RADIUS + 2.0)

func _apply_q_hit(target: Node) -> void:
	if target == _player_ref:
		return
	var dir := Vector2.ZERO
	if _player_ref:
		dir = (target.global_position - _player_ref.global_position).normalized()
	var dmg := DAMAGE_Q + ProgressionManager.get_skill_damage_bonus()
	if target.has_method("take_damage"):
		target.take_damage(dmg, dir)
	elif target.has_method("receive_hit"):
		target.receive_hit(dmg, dir)
