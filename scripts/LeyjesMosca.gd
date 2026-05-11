extends Area2D

# spritesheet: 512x320 → 8 cols x 5 rows, frame 64x64
# rows 0-4: S, SE, E, NE, N — SW/W/NW sao espelhos de SE/E/NE via flip_h
const SPRITE_PATH := "res://assets/enemies/lejyes_mosca/walk/spritesheet_personagem3.png"
const FRAME_W    := 64
const FRAME_H    := 64
const WALK_COLS  := 8
const WALK_FPS   := 8.0
const BOSS_SCALE := 2.0

const ROW_DIRS := ["S", "SE", "E", "NE", "N"]

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
var _player: Node     = null
var _last_facing      := "S"
var _col_shape: CollisionShape2D
var _sprite: AnimatedSprite2D

func _ready() -> void:
	var col    := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 28.0
	col.shape = circle
	add_child(col)
	_col_shape = col
	_setup_sprite()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

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
			atlas.region      = Rect2(col * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)
			frames.add_frame(anim, atlas)
	_sprite                = AnimatedSprite2D.new()
	_sprite.sprite_frames  = frames
	_sprite.scale          = Vector2(BOSS_SCALE, BOSS_SCALE)
	_sprite.centered       = false
	_sprite.offset         = Vector2(-FRAME_W / 2.0, -FRAME_H)
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

	z_index = int(global_position.y / 8.0)

func _resolve_facing(d: Vector2) -> String:
	var deg := fmod(rad_to_deg(d.angle()) + 360.0, 360.0)
	const DIRS: Array[String] = ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]
	return DIRS[int((deg + 22.5) / 45.0) % 8]

func _play_walk(facing: String) -> void:
	var flip        := facing in ["SW", "W", "NW"]
	const BASE      := {"SW": "SE", "W": "E", "NW": "NE"}
	var anim: String = "walk_" + (BASE[facing] as String if flip else facing)
	_sprite.flip_h = flip
	if _sprite.animation != anim or not _sprite.is_playing():
		_sprite.play(anim)

func _play_idle(facing: String) -> void:
	var flip        := facing in ["SW", "W", "NW"]
	const BASE      := {"SW": "SE", "W": "E", "NW": "NE"}
	var anim: String = "walk_" + (BASE[facing] as String if flip else facing)
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

func _trigger_phase2() -> void:
	_phase2_triggered = true
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
	set_physics_process(false)
	_col_shape.set_deferred("disabled", true)
	_sprite.stop()
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
	draw_rect(Rect2(x, BAR_Y, BAR_W, BAR_H), Color(0.08, 0.05, 0.0, 0.9))
	draw_rect(Rect2(x, BAR_Y, fill, BAR_H), Color(1.0, 0.75, 0.0, 1.0))

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		_player       = body
		_damage_timer = 0.0

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
