extends Area2D

var MAX_HEALTH      := 20.0
var DAMAGE          := 8.0
var xp_reward       := 15.0
var DAMAGE_INTERVAL := 1.0
var MOVE_SPEED      := 160.0

const DETECT_RANGE := 220.0
const STOP_RANGE   := 12.0

const BAR_W := 60.0
const BAR_H := 6.0
const BAR_Y := -35.0

var current_health  := MAX_HEALTH
var is_dead         := false
var _damage_timer   := 0.0
var _player: Node   = null
var _frenzy_applied := false
var _col_shape: CollisionShape2D

func _ready() -> void:
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	col.shape = circle
	add_child(col)
	_col_shape = col
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
	var player_node: Node2D = get_tree().get_first_node_in_group("player")
	if player_node == null or is_dead:
		return

	var dist := global_position.distance_to(player_node.global_position)
	if dist > STOP_RANGE:
		var dir := (player_node.global_position - global_position).normalized()
		position += dir * MOVE_SPEED * delta

	z_index = int(global_position.y / 8.0)

	if _player == null:
		return
	_damage_timer -= delta
	if _damage_timer <= 0.0:
		_damage_timer = DAMAGE_INTERVAL
		AudioManager.play_sfx("enemy_attack")
		_player.take_damage(DAMAGE, Vector2.ZERO)

func take_damage(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	current_health = maxf(current_health - amount, 0.0)
	queue_redraw()
	_flash_hit()
	JuiceManager.spawn_blood(global_position, get_parent())
	JuiceManager.spawn_damage_number(amount, global_position, get_parent())
	if amount >= 20.0:
		JuiceManager.apply_hitstop(0.06)
		JuiceManager.add_trauma(0.25)
	if direction != Vector2.ZERO:
		position += direction * 18.0
	if current_health <= 0.0:
		_die()

func _flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2.0, 0.4, 0.4, 1.0), 0.05)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

func receive_hit(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	take_damage(amount, direction)

func _die() -> void:
	is_dead = true
	_player = null
	set_physics_process(false)
	_col_shape.set_deferred("disabled", true)
	ProgressionManager.add_xp(xp_reward)
	ProgressionManager.add_fragments(randi_range(1, 3))
	AudioManager.play_sfx("enemy_die")
	JuiceManager.spawn_blood(global_position, get_parent())
	JuiceManager.apply_hitstop(0.08)
	JuiceManager.add_trauma(0.3)
	var player_node := get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if player_node and player_node.has_method("heal"):
		player_node.heal(2.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func apply_frenzy() -> void:
	if _frenzy_applied:
		return
	_frenzy_applied = true
	DAMAGE     *= 1.5
	MOVE_SPEED *= 1.5
	modulate = Color(1.3, 0.3, 0.2, 1.0)

func _draw() -> void:
	if not is_dead:
		draw_circle(Vector2.ZERO, 12.0, Color(0.1, 0.8, 0.2, 0.9))
	if is_dead or current_health >= MAX_HEALTH:
		return
	var x := -BAR_W / 2.0
	draw_rect(Rect2(x, BAR_Y, BAR_W, BAR_H), Color(0.15, 0.0, 0.0, 0.85))
	var fill := BAR_W * (current_health / MAX_HEALTH)
	draw_rect(Rect2(x, BAR_Y, fill, BAR_H), Color(0.9, 0.1, 0.1, 1.0))

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		_player = body
		_damage_timer = 0.0

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
