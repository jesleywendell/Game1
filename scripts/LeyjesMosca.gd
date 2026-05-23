extends Area2D

# spritesheet: 512x320 → 8 cols x 5 rows, frame 64x64
# rows 0-4: S, SE, E, NE, N — SW/W/NW sao espelhos de SE/E/NE via flip_h
const SPRITE_PATH := "res://assets/enemies/lejyes_mosca/walk/spritesheet_personagem3.png"
const FRAME_W    := 64
const FRAME_H    := 64
const WALK_COLS  := 8
const WALK_FPS   := 8.0
const BOSS_SCALE := 2.0

const ROW_DIRS := ["S", "SE", "E", "NE"]  # rows 1-4; row 0 = idle/facing (não usar para walk)

const SUMMON_FLY      := preload("res://scripts/SummonedFly.gd")
const SUMMON_CD_P1    := 9.0
const SUMMON_CD_P2    := 5.0
const MAX_FLIES       := 6

const FIREBALL        := preload("res://scripts/LeyjesFireball.gd")
const FIREBALL_CD_P1  := 5.5
const FIREBALL_CD_P2  := 3.0

const BLOOD_CIRCLE_SKILL  := preload("res://scripts/BloodCircleSkill.gd")
const BLOOD_CIRCLE_CD_P1  := 18.0
const BLOOD_CIRCLE_CD_P2  := 11.0

const MAP_X := Vector2(-1600.0, 2080.0)
const MAP_Y := Vector2(8.0, 1848.0)
const DETECT_RANGE := 450.0
const STOP_RANGE   := 28.0

const BAR_W := 140.0
const BAR_H := 9.0
const BAR_Y := -148.0  # acima do topo do sprite escalado (64*2=128 + margem)

var MAX_HEALTH      := 450.0
var DAMAGE          := 40.0
var MOVE_SPEED      := 60.0
var DAMAGE_INTERVAL := 0.9
var xp_reward       := 250.0
var is_boss         := false

var current_health    := MAX_HEALTH
var is_dead           := false
var _phase2_triggered := false
var _frenzy_applied   := false
var _damage_timer     := 0.0
var _summon_timer     := 5.0
var _summon_cd        := SUMMON_CD_P1
var _fireball_timer   := 3.0
var _fireball_cd      := FIREBALL_CD_P1
var _blood_circle_timer := 8.0
var _blood_circle_cd    := BLOOD_CIRCLE_CD_P1
var _casting_blood      := false
var _blood_frames: Array[Texture2D] = []
var _player: Node     = null
var _cached_player: Node2D = null
var _last_facing      := "S"
var _col_shape: CollisionShape2D
var _sprite: AnimatedSprite2D

func _ready() -> void:
	var col    := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 56.0
	col.shape = circle
	add_child(col)
	_col_shape = col
	_setup_sprite()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	await get_tree().create_timer(0.4).timeout
	AudioManager.play_sfx("lejess_laugh")
	_cached_player = get_tree().get_first_node_in_group("player")

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
	for i in 25:
		var path: String = "res://assets/enemies/lejyes_mosca/skills/Blood - Magic Effect/Blood-Magic-Effect_%02d.png" % (i + 1)
		if ResourceLoader.exists(path):
			_blood_frames.append(load(path) as Texture2D)

func _physics_process(delta: float) -> void:
	if not is_inside_tree() or is_dead:
		return
	var player_node: Node2D = _cached_player
	if not is_instance_valid(player_node):
		return

	var dist   := global_position.distance_to(player_node.global_position)
	var moving := dist > STOP_RANGE and not _casting_blood

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

	if is_boss:
		_summon_timer -= delta
		if _summon_timer <= 0.0:
			_do_summon()
			_summon_timer = _summon_cd
		_fireball_timer -= delta
		if _fireball_timer <= 0.0:
			_fireball_timer = _fireball_cd
			_fire_fireball(player_node)
		_blood_circle_timer -= delta
		if _blood_circle_timer <= 0.0 and not _casting_blood:
			_blood_circle_timer = _blood_circle_cd
			_cast_blood_circle()

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
		position += direction * 14.0
	if is_boss and not _phase2_triggered and current_health <= MAX_HEALTH * 0.5:
		_trigger_phase2()
	if current_health <= 0.0:
		_die()

func receive_hit(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	take_damage(amount, direction)

func _do_summon() -> void:
	var alive := get_tree().get_nodes_in_group("summoned_flies").size()
	if alive >= MAX_FLIES:
		return
	var count := 3 if _phase2_triggered else 2
	count = mini(count, MAX_FLIES - alive)

	AudioManager.play_sfx("lejess_attack")
	var flash := create_tween()
	flash.tween_property(self, "modulate", Color(0.55, 0.20, 1.00, 1.0), 0.08)
	flash.tween_property(self, "modulate", Color(1.00, 1.00, 1.00, 1.0), 0.40)
	JuiceManager.add_trauma(0.12)

	for i in count:
		var angle  := randf() * TAU
		var dist   := randf_range(55.0, 105.0)
		var offset := Vector2(cos(angle), sin(angle)) * dist
		var pos    := global_position + offset
		_spawn_blood_vfx(pos)
		var fly    := SUMMON_FLY.new()
		fly.global_position = pos
		get_parent().add_child(fly)

func _trigger_phase2() -> void:
	_phase2_triggered  = true
	_summon_cd         = SUMMON_CD_P2
	_fireball_cd       = FIREBALL_CD_P2
	_blood_circle_cd   = BLOOD_CIRCLE_CD_P2
	_blood_circle_timer = 3.0
	MOVE_SPEED      *= 1.7
	DAMAGE          *= 1.3
	DAMAGE_INTERVAL  = 0.65
	var tween        := create_tween()
	tween.tween_property(self, "modulate", Color(2.0, 1.8, 0.2, 1.0), 0.1)
	tween.tween_property(self, "modulate", Color(1.2, 1.0, 1.0, 1.0), 0.6)
	JuiceManager.add_trauma(0.55)
	JuiceManager.apply_hitstop(0.15)
	AudioManager.play_sfx("boss_phase2")

func _flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2.0, 0.4, 0.4, 1.0), 0.05)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

func _die() -> void:
	is_dead = true
	_player = null
	_cached_player = null
	set_physics_process(false)
	_col_shape.set_deferred("disabled", true)
	_sprite.stop()
	for fly in get_tree().get_nodes_in_group("summoned_flies"):
		if fly.has_method("die_fade"):
			fly.die_fade()
	for fb in get_tree().get_nodes_in_group("lejess_projectiles"):
		if is_instance_valid(fb):
			fb.queue_free()
	ProgressionManager.add_xp(xp_reward)
	ProgressionManager.add_fragments(randi_range(20, 40) if is_boss else randi_range(3, 8))
	AudioManager.play_sfx("enemy_die")
	JuiceManager.spawn_blood(global_position, get_parent())
	JuiceManager.apply_hitstop(0.15)
	JuiceManager.add_trauma(0.6)
	var player_node := get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if player_node and player_node.has_method("heal"):
		player_node.heal(30.0 if is_boss else 10.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _fire_fireball(target: Node2D) -> void:
	if not is_inside_tree() or target == null:
		return
	var base_dir := (target.global_position - global_position).normalized()
	var count    := 2 if _phase2_triggered else 1
	var spd      := 200.0 if _phase2_triggered else 150.0
	var dmg      := 28.0  if _phase2_triggered else 22.0
	var spread   := deg_to_rad(20.0)
	for i in count:
		var offset_angle := (i - (count - 1) / 2.0) * spread
		var fb            := FIREBALL.new()
		fb.direction       = base_dir.rotated(offset_angle)
		fb.speed           = spd
		fb.damage          = dmg
		fb.global_position = global_position
		get_parent().add_child(fb)

func _spawn_blood_vfx(pos: Vector2) -> void:
	if _blood_frames.is_empty():
		return
	var sf := SpriteFrames.new()
	sf.add_animation("play")
	sf.set_animation_speed("play", 14.0)
	sf.set_animation_loop("play", false)
	for tex in _blood_frames:
		sf.add_frame("play", tex)
	var spr              := AnimatedSprite2D.new()
	spr.sprite_frames     = sf
	spr.scale             = Vector2(1.2, 1.2)
	spr.texture_filter    = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.z_index           = 4
	get_parent().add_child(spr)
	spr.global_position   = pos
	spr.play("play")
	spr.animation_finished.connect(spr.queue_free)

func apply_frenzy() -> void:
	if _frenzy_applied:
		return
	_frenzy_applied = true
	DAMAGE     *= 1.5
	MOVE_SPEED *= 1.5
	modulate    = Color(1.3, 0.3, 0.2, 1.0)

func _cast_blood_circle() -> void:
	_casting_blood = true
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2.0, 0.15, 0.15, 1.0), 0.15)
	tween.tween_property(self, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.35)
	for i in 4:
		var angle := TAU * i / 4.0
		_spawn_blood_vfx(global_position + Vector2(cos(angle), sin(angle)) * 45.0)
	AudioManager.play_sfx("lejess_attack")
	await get_tree().create_timer(0.5).timeout
	if is_dead or not is_inside_tree():
		_casting_blood = false
		return
	var circle := BLOOD_CIRCLE_SKILL.new()
	circle.global_position = global_position
	get_parent().add_child(circle)
	await get_tree().create_timer(3.5).timeout
	_casting_blood = false
	if not is_dead and is_inside_tree():
		var t := create_tween()
		t.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)

func _draw() -> void:
	if is_dead or current_health >= MAX_HEALTH or not is_boss:
		return
	var x    := -BAR_W / 2.0
	var fill := BAR_W * (current_health / MAX_HEALTH)
	draw_rect(Rect2(x, BAR_Y, BAR_W, BAR_H), Color(0.08, 0.05, 0.0, 0.9))
	draw_rect(Rect2(x, BAR_Y, fill, BAR_H), Color(1.0, 0.75, 0.0, 1.0))

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		_player       = body
		_damage_timer = 0.0

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
