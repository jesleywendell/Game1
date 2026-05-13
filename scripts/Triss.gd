extends Area2D

# spritesheet: 512x320 → 8 cols x 5 rows, frame 64x64
# rows 0-4: S, SE, E, NE, N — SW/W/NW sao espelhos de SE/E/NE via flip_h
const SPRITE_PATH := "res://assets/enemies/triss/walk/spritesheet_personagem2.png"
const FRAME_W    := 64
const FRAME_H    := 64
const WALK_COLS  := 8
const WALK_FPS   := 8.0
const BOSS_SCALE := 1.5

const ROW_DIRS := ["S", "SE", "E", "NE"]  # rows 1-4; row 0 = idle/facing (não usar para walk)

const MAP_X := Vector2(-1600.0, 2080.0)
const MAP_Y := Vector2(8.0, 1848.0)
const DETECT_RANGE := 400.0
const STOP_RANGE   := 22.0

const BAR_W := 110.0
const BAR_H := 8.0
const BAR_Y := -112.0  # acima do topo do sprite escalado (64*1.5=96 + margem)

const TRISS_BOLT := preload("res://scripts/TrissBolt.gd")
const TRISS_ORB  := preload("res://scripts/TrissOrb.gd")

# Fase 1: 2 orbs orbitando, volley de 2 bolts a cada 3.5s
# Fase 2: 3 orbs, volley de 3 bolts a cada 2.0s, bolts mais rápidos
const VOLLEY_CD    := 3.5
const VOLLEY_CD_P2 := 2.0
const BOLT_DMG     := 14.0
const BOLT_DMG_P2  := 20.0
const BOLT_SPEED   := 185.0
const BOLT_SPEED_P2:= 240.0
const SPREAD_DEG   := 22.0   # graus entre bolts do volley

var MAX_HEALTH      := 280.0
var DAMAGE          := 28.0
var MOVE_SPEED      := 75.0
var DAMAGE_INTERVAL := 1.0
var xp_reward       := 150.0
var is_boss         := false

var current_health    := MAX_HEALTH
var is_dead           := false
var _phase2_triggered := false
var _frenzy_applied   := false
var _damage_timer     := 0.0
var _volley_timer     := 2.0   # delay inicial antes do primeiro volley
var _orbs: Array      = []
var _player: Node     = null
var _last_facing      := "S"
var _col_shape: CollisionShape2D
var _sprite: AnimatedSprite2D

func _ready() -> void:
	var col    := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 22.0
	col.shape = circle
	add_child(col)
	_col_shape = col
	_setup_sprite()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_spawn_orbs(2)
	# Risada logo após spawnar (diálogo já terminou)
	await get_tree().create_timer(0.4).timeout
	AudioManager.play_sfx("triss_laugh")

func _setup_sprite() -> void:
	var tex: Texture2D = load(SPRITE_PATH)
	var frames         := SpriteFrames.new()
	for row in ROW_DIRS.size():
		var anim: String = "walk_" + (ROW_DIRS[row] as String)
		frames.add_animation(anim)
		frames.set_animation_speed(anim, WALK_FPS)
		frames.set_animation_loop(anim, true)
		for col in WALK_COLS:
			var atlas        := AtlasTexture.new()
			atlas.atlas       = tex
			atlas.region      = Rect2(col * FRAME_W, (row + 1) * FRAME_H, FRAME_W, FRAME_H)
			frames.add_frame(anim, atlas)
	_sprite                = AnimatedSprite2D.new()
	_sprite.sprite_frames  = frames
	_sprite.scale          = Vector2(BOSS_SCALE, BOSS_SCALE)
	_sprite.centered       = true
	_sprite.offset         = Vector2(0.0, -FRAME_H / 2.0)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_sprite.play("walk_S")

func _physics_process(delta: float) -> void:
	if not is_inside_tree() or is_dead:
		return
	var player_node: Node2D = get_tree().get_first_node_in_group("player")
	if player_node == null:
		return

	var dist   := global_position.distance_to(player_node.global_position)
	var moving := dist > STOP_RANGE

	if moving:
		var dir := (player_node.global_position - global_position).normalized()
		position   += dir * MOVE_SPEED * delta
		position.x  = clampf(position.x, MAP_X.x, MAP_X.y)
		position.y  = clampf(position.y, MAP_Y.x, MAP_Y.y)
		_last_facing = _resolve_facing(dir)
		_play_walk(_last_facing)
	else:
		_play_idle(_last_facing)

	if _player != null:
		_damage_timer -= delta
		if _damage_timer <= 0.0:
			_damage_timer = DAMAGE_INTERVAL
			AudioManager.play_sfx("enemy_attack")
			_player.take_damage(DAMAGE, Vector2.ZERO)

	# Volley de bolts teleguiados
	var vcd := VOLLEY_CD_P2 if _phase2_triggered else VOLLEY_CD
	_volley_timer -= delta
	if _volley_timer <= 0.0:
		_volley_timer = vcd
		_fire_volley(player_node)

	z_index = int(global_position.y / 8.0)

func _resolve_facing(d: Vector2) -> String:
	var deg := fmod(rad_to_deg(d.angle()) + 360.0, 360.0)
	const DIRS: Array[String] = ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]
	return DIRS[int((deg + 22.5) / 45.0) % 8]

func _play_walk(facing: String) -> void:
	var flip := facing in ["SW", "W", "NW"]
	const REMAP := {"SW": "SE", "W": "E", "NW": "NE", "N": "NE"}
	var dir: String = REMAP[facing] if REMAP.has(facing) else facing
	var anim: String = "walk_" + dir
	_sprite.flip_h = flip
	if _sprite.animation != anim or not _sprite.is_playing():
		_sprite.play(anim)

func _play_idle(facing: String) -> void:
	var flip := facing in ["SW", "W", "NW"]
	const REMAP := {"SW": "SE", "W": "E", "NW": "NE", "N": "NE"}
	var dir: String = REMAP[facing] if REMAP.has(facing) else facing
	var anim: String = "walk_" + dir
	_sprite.flip_h = flip
	if _sprite.animation != anim:
		_sprite.animation = anim
	if _sprite.is_playing():
		_sprite.stop()
		_sprite.frame = 0

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
		position += direction * 16.0
	if is_boss and not _phase2_triggered and current_health <= MAX_HEALTH * 0.5:
		_trigger_phase2()
	if current_health <= 0.0:
		_die()

func receive_hit(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	take_damage(amount, direction)

func _spawn_orbs(count: int) -> void:
	for i in count:
		var orb := TRISS_ORB.new()
		orb.set_initial_angle(i * TAU / count)
		add_child(orb)
		_orbs.append(orb)

func _fire_volley(target: Node2D) -> void:
	if not is_inside_tree() or target == null:
		return
	var count   := 3 if _phase2_triggered else 2
	var base_dir := (target.global_position - global_position).normalized()
	var spd     := BOLT_SPEED_P2 if _phase2_triggered else BOLT_SPEED
	var dmg     := BOLT_DMG_P2  if _phase2_triggered else BOLT_DMG
	var spread  := deg_to_rad(SPREAD_DEG)
	# Distribui os bolts em fan centrado na direção do jogador
	for i in count:
		var offset_angle := (i - (count - 1) / 2.0) * spread
		var bolt          := TRISS_BOLT.new()
		bolt.direction     = base_dir.rotated(offset_angle)
		bolt.speed         = spd
		bolt.damage        = dmg
		bolt.global_position = global_position
		get_parent().add_child(bolt)
	AudioManager.play_sfx("triss_attack")
	var flash := create_tween()
	flash.tween_property(self, "modulate", Color(1.6, 0.4, 2.0, 1.0), 0.07)
	flash.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.22)

func _trigger_phase2() -> void:
	_phase2_triggered = true
	MOVE_SPEED      *= 1.6
	DAMAGE_INTERVAL  = 0.7
	# Adiciona 3º orb e acelera todos
	for orb in _orbs:
		if is_instance_valid(orb):
			orb.orbit_speed *= 1.7
			orb.damage      *= 1.4
	_spawn_orbs(1)   # terceiro orb começa na posição intermediária
	if not _orbs.is_empty() and is_instance_valid(_orbs.back()):
		_orbs.back().set_initial_angle(TAU * 2.0 / 3.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2.0, 0.5, 2.0, 1.0), 0.1)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
	JuiceManager.add_trauma(0.45)
	JuiceManager.apply_hitstop(0.12)
	AudioManager.play_sfx("boss_phase2")

func _flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2.0, 0.4, 0.4, 1.0), 0.05)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

func _die() -> void:
	is_dead = true
	_player = null
	set_physics_process(false)
	_col_shape.set_deferred("disabled", true)
	_sprite.stop()
	if is_inside_tree():
		for bolt in get_tree().get_nodes_in_group("triss_projectiles"):
			if is_instance_valid(bolt):
				bolt.queue_free()
	ProgressionManager.add_xp(xp_reward)
	ProgressionManager.add_fragments(randi_range(12, 25) if is_boss else randi_range(2, 5))
	AudioManager.play_sfx("enemy_die")
	JuiceManager.spawn_blood(global_position, get_parent())
	JuiceManager.apply_hitstop(0.12)
	JuiceManager.add_trauma(0.45)
	var player_node := get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if player_node and player_node.has_method("heal"):
		player_node.heal(20.0 if is_boss else 8.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.45)
	tween.tween_callback(queue_free)

func apply_frenzy() -> void:
	if _frenzy_applied:
		return
	_frenzy_applied = true
	DAMAGE     *= 1.5
	MOVE_SPEED *= 1.5
	modulate    = Color(1.3, 0.3, 0.2, 1.0)

func _draw() -> void:
	if is_dead or current_health >= MAX_HEALTH or not is_boss:
		return
	var x    := -BAR_W / 2.0
	var fill := BAR_W * (current_health / MAX_HEALTH)
	draw_rect(Rect2(x, BAR_Y, BAR_W, BAR_H), Color(0.1, 0.0, 0.12, 0.9))
	draw_rect(Rect2(x, BAR_Y, fill, BAR_H), Color(0.75, 0.2, 0.9, 1.0))

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		_player       = body
		_damage_timer = 0.0

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
