extends Area2D

var MAX_HEALTH      := 30.0
var DAMAGE          := 10.0
var xp_reward       := 20.0
var DAMAGE_INTERVAL := 1.0
var MOVE_SPEED      := 120.0

const DETECT_RANGE := 200.0
const STOP_RANGE   := 18.0
const MAP_X        := Vector2(-1600.0, 2080.0)
const MAP_Y        := Vector2(8.0, 1848.0)

const SKEL_PATH  := "res://assets/enemies/skeleton/Skeleton.png"
const SPEAR_PATH := "res://assets/items/spear/spear_00.png"
const FRAME_W    := 64
const FRAME_H    := 64
const SKEL_SCALE := 0.85
const WALK_FPS   := 8.0

# Rows 0-3 = S,SE,E,NE (7 frames each); rows 4-7 = N,NW,W,SW (8 frames each)
const WALK_DIRS: Array[String]  = ["S","SE","E","NE","N","NW","W","SW"]
const WALK_FRAMES: Array[int]   = [7, 7, 7, 7, 8, 8, 8, 8]

var current_health  := MAX_HEALTH
var is_dead         := false
var _damage_timer   := 0.0
var _player: Node   = null
var _frenzy_applied := false
var _col_shape: CollisionShape2D
var _sprite: AnimatedSprite2D
var _spear: Sprite2D
var _last_facing    := "S"

func _ready() -> void:
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	col.shape = circle
	add_child(col)
	_col_shape = col
	_setup_sprite()
	_setup_spear()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _setup_sprite() -> void:
	var tex: Texture2D = load(SKEL_PATH)
	var frames := SpriteFrames.new()
	for row in WALK_DIRS.size():
		var anim := "walk_" + WALK_DIRS[row]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, WALK_FPS)
		frames.set_animation_loop(anim, true)
		for col in WALK_FRAMES[row]:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)
			frames.add_frame(anim, atlas)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.scale = Vector2(SKEL_SCALE, SKEL_SCALE)
	_sprite.centered = false
	_sprite.offset = Vector2(-FRAME_W / 2.0, -FRAME_H)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)

func _setup_spear() -> void:
	_spear = Sprite2D.new()
	_spear.texture = load(SPEAR_PATH)
	_spear.scale = Vector2(0.75, 0.75)
	_spear.position = Vector2(18.0, -20.0)
	_spear.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_spear)

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
	var player_node: Node2D = get_tree().get_first_node_in_group("player")
	if player_node == null or is_dead:
		return

	var dist    := global_position.distance_to(player_node.global_position)
	var dir     := Vector2.ZERO
	var moving  := dist > STOP_RANGE

	if moving:
		dir = (player_node.global_position - global_position).normalized()
		position += dir * MOVE_SPEED * delta
		position.x = clampf(position.x, MAP_X.x, MAP_X.y)
		position.y = clampf(position.y, MAP_Y.x, MAP_Y.y)
		_last_facing = _resolve_facing(dir)

	var anim := "walk_" + _last_facing
	if moving:
		if _sprite.animation != anim or not _sprite.is_playing():
			_sprite.play(anim)
	else:
		if _sprite.animation != anim:
			_sprite.animation = anim
		if _sprite.is_playing():
			_sprite.stop()
			_sprite.frame = 0

	# Spear: flip and reposition based on facing left or right
	var facing_left := _last_facing in ["W","SW","NW"]
	_spear.flip_h      = facing_left
	_spear.position.x  = -18.0 if facing_left else 18.0

	z_index        = int(global_position.y / 8.0)
	_spear.z_index = z_index + 1

	if _player == null:
		return
	_damage_timer -= delta
	if _damage_timer <= 0.0:
		_damage_timer = DAMAGE_INTERVAL
		AudioManager.play_sfx("enemy_attack")
		_player.take_damage(DAMAGE, Vector2.ZERO)

func _resolve_facing(d: Vector2) -> String:
	var deg := fmod(rad_to_deg(d.angle()) + 360.0, 360.0)
	# 0=E,45=SE,90=S,135=SW,180=W,225=NW,270=N,315=NE
	const DIRS: Array[String] = ["E","SE","S","SW","W","NW","N","NE"]
	return DIRS[int((deg + 22.5) / 45.0) % 8]

func take_damage(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	current_health = maxf(current_health - amount, 0.0)
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
	_col_shape.set_deferred("disabled", true)
	_sprite.stop()
	ProgressionManager.add_xp(xp_reward)
	ProgressionManager.add_fragments(randi_range(1, 3))
	AudioManager.play_sfx("enemy_die")
	JuiceManager.spawn_blood(global_position, get_parent())
	JuiceManager.apply_hitstop(0.08)
	JuiceManager.add_trauma(0.3)
	var player_node := get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if player_node and player_node.has_method("heal"):
		player_node.heal(3.0)
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

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		_player = body
		_damage_timer = 0.0

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
