extends Area2D

# Walk spritesheet: 1086x1448 → 6 colunas × 8 linhas, cada frame 181×181
const FRAME_W    := 181
const FRAME_H    := 181
const WALK_COLS  := 6
const WALK_ROWS  := 8
const WALK_FPS   := 8.0
const MAP_X := Vector2(-1600.0, 2080.0)
const MAP_Y := Vector2(8.0, 1848.0)

var MOVE_SPEED      := 55.0
const DETECT_RANGE    := 380.0
const STOP_RANGE      := 24.0

var SKILL_COOLDOWN  := 6.0
const SKILL_RANGE     := 340.0
const SKILL_DAMAGE    := 35.0
const CHARGE_SPEED    := 230.0
const CHARGE_DURATION := 0.38
const CHARGE_HIT_DIST := 64.0

const BAR_W := 70.0
const BAR_H := 6.0
const BAR_Y := -115.0

var DAMAGE          := 20.0
var DAMAGE_INTERVAL := 1.0
var MAX_HEALTH      := 150.0

var current_health := MAX_HEALTH
var is_dead        := false
var xp_reward      := 65.0
var is_boss            := false
var _phase2_triggered  := false
var _damage_timer  := 0.0
var _skill_timer   := SKILL_COOLDOWN * 0.5
var _player: Node  = null
var _state         := "idle"
var _charge_dir    := Vector2.ZERO
var _charge_timer  := 0.0
var _frenzy_applied := false
var _last_dir      := Vector2.RIGHT

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Ordem das linhas na spritesheet (topo → baixo).
# Se as direções aparecerem erradas no jogo, reordene estes valores.
const ROW_ORDER := [
	"walk_SE", "walk_S", "walk_SW", "walk_W",
	"walk_NW", "walk_N", "walk_NE", "walk_E",
]

# Ângulo da velocidade (0° = direita, sentido horário) → animação, 8 setores de 45°
const SECTOR_ANIMS := [
	"walk_E", "walk_SE", "walk_S", "walk_SW",
	"walk_W", "walk_NW", "walk_N", "walk_NE",
]

func _ready() -> void:
	_setup_animation()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _setup_animation() -> void:
	var frames := SpriteFrames.new()
	var tex: Texture2D = load("res://assets/enemies/knight_coxinha/walk/knight_coxinha_walk.png")
	for row_idx in WALK_ROWS:
		var anim: String = ROW_ORDER[row_idx]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, WALK_FPS)
		frames.set_animation_loop(anim, true)
		for col in WALK_COLS:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * FRAME_W, row_idx * FRAME_H, FRAME_W, FRAME_H)
			frames.add_frame(anim, atlas)
	sprite.sprite_frames = frames
	# Ancora nos pes (base do frame) em vez de centralizar no meio.
	# Evita o efeito de "sprite se movendo dentro de si" causado pela
	# variacao de posicao do personagem entre frames do ciclo de caminhada.
	sprite.centered = false
	sprite.offset = Vector2(-FRAME_W / 2.0, -FRAME_H)
	sprite.play("walk_SE")

func _anim_for_dir(dir: Vector2) -> String:
	var deg := fmod(rad_to_deg(dir.angle()) + 360.0, 360.0)
	return SECTOR_ANIMS[int((deg + 22.5) / 45.0) % 8]

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var player_node: Node2D = get_tree().get_first_node_in_group("player")
	if player_node == null:
		return

	if _state == "skill_charge":
		_charge_timer -= delta
		position += _charge_dir * CHARGE_SPEED * delta
		position.x = clampf(position.x, MAP_X.x, MAP_X.y)
		position.y = clampf(position.y, MAP_Y.x, MAP_Y.y)
		sprite.play(_anim_for_dir(_charge_dir))
		_check_charge_hit(player_node)
		if _charge_timer <= 0.0:
			_end_skill()
		z_index = int(global_position.y / 8.0)
		return

	if _state == "skill_windup":
		z_index = int(global_position.y / 8.0)
		return

	_skill_timer -= delta
	var dist := global_position.distance_to(player_node.global_position)

	if _skill_timer <= 0.0 and dist < SKILL_RANGE:
		_start_skill(player_node)
		return

	if dist < DETECT_RANGE and dist > STOP_RANGE:
		var dir := (player_node.global_position - global_position).normalized()
		_last_dir = dir
		position += dir * MOVE_SPEED * delta
		position.x = clampf(position.x, MAP_X.x, MAP_X.y)
		position.y = clampf(position.y, MAP_Y.x, MAP_Y.y)
		sprite.play(_anim_for_dir(dir))
		_state = "walk"
	else:
		if _state != "idle":
			_state = "idle"
			sprite.stop()
			sprite.animation = _anim_for_dir(_last_dir)
			sprite.frame = 0

	if _player != null:
		_damage_timer -= delta
		if _damage_timer <= 0.0:
			_damage_timer = DAMAGE_INTERVAL
			_player.take_damage(DAMAGE, Vector2.ZERO)

	z_index = int(global_position.y / 8.0)

func _start_skill(player_node: Node2D) -> void:
	_skill_timer = SKILL_COOLDOWN
	_charge_dir = (player_node.global_position - global_position).normalized()
	_last_dir = _charge_dir
	_state = "skill_windup"
	sprite.stop()
	sprite.animation = _anim_for_dir(_charge_dir)
	sprite.frame = 0
	await get_tree().create_timer(0.55).timeout
	if is_dead:
		return
	_state = "skill_charge"
	_charge_timer = CHARGE_DURATION
	JuiceManager.add_trauma(0.1)

func _check_charge_hit(player_node: Node2D) -> void:
	if global_position.distance_to(player_node.global_position) < CHARGE_HIT_DIST:
		if player_node.has_method("take_damage"):
			player_node.take_damage(SKILL_DAMAGE, _charge_dir)
		_end_skill()

func _end_skill() -> void:
	_state = "idle"
	JuiceManager.add_trauma(0.18)

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
		position += direction * 14.0
	if is_boss and not _phase2_triggered and current_health <= MAX_HEALTH * 0.5:
		_phase2_triggered = true
		MOVE_SPEED = 95.0
		SKILL_COOLDOWN = 3.0
		var tween2 := create_tween()
		tween2.tween_property(self, "modulate", Color(2.0, 1.8, 0.2, 1.0), 0.1)
		tween2.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)
		JuiceManager.add_trauma(0.4)
		JuiceManager.apply_hitstop(0.12)
		AudioManager.play_sfx("boss_phase2")
	if current_health <= 0.0:
		_die()

func receive_hit(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	take_damage(amount, direction)

func _flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2.0, 0.4, 0.4, 1.0), 0.05)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

func _die() -> void:
	is_dead = true
	_player = null
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	ProgressionManager.add_xp(xp_reward)
	var frag_amount := randi_range(10, 20) if is_boss else randi_range(1, 3)
	ProgressionManager.add_fragments(frag_amount)
	AudioManager.play_sfx("enemy_die")
	JuiceManager.spawn_blood(global_position, get_parent())
	JuiceManager.apply_hitstop(0.1)
	JuiceManager.add_trauma(0.35)
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
	if is_dead or current_health >= MAX_HEALTH or not is_boss:
		return
	var x := -BAR_W / 2.0
	draw_rect(Rect2(x, BAR_Y, BAR_W, BAR_H), Color(0.15, 0.0, 0.0, 0.85))
	var fill := BAR_W * (current_health / MAX_HEALTH)
	draw_rect(Rect2(x, BAR_Y, fill, BAR_H), Color(0.85, 0.15, 0.15, 1.0))

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		_player = body
		_damage_timer = 0.0

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
