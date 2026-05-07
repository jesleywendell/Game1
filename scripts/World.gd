extends Node2D

const UPGRADE_PANEL := preload("res://scenes/UpgradePanel.tscn")
const PAUSE_MENU    := preload("res://scenes/PauseMenu.tscn")

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD

var _wave_manager: Node
var _enemies_killed: int = 0
var _run_start_time: int = 0
var _upgrade_panel: CanvasLayer
var _fragments_at_start: int = 0
var _light_texture: Texture2D

func _ready() -> void:
	hud.layer = 2
	player.add_to_group("player")
	player.health_changed.connect(hud.on_health_changed)
	player.died.connect(hud.on_player_died)
	add_child(PAUSE_MENU.instantiate())
	var upgrade_panel := UPGRADE_PANEL.instantiate()
	add_child(upgrade_panel)
	_upgrade_panel = upgrade_panel
	ProgressionManager.leveled_up.connect(func(_lvl): _upgrade_panel.on_leveled_up())
	_light_texture = _make_light_texture()
	_setup_atmosphere()
	_setup_player_light()
	_setup_camera_limits()

	_wave_manager = load("res://scripts/WaveManager.gd").new()
	_wave_manager.name = "WaveManager"
	add_child(_wave_manager)
	_wave_manager.init(self)
	_wave_manager.wave_cleared.connect(_on_wave_cleared)
	_wave_manager.wave_started.connect(_on_wave_started)
	_wave_manager.wave_started.connect(hud.on_wave_started)
	hud.set_skill_manager(player.get_node("SkillManager"))
	_wave_manager.area_cleared.connect(_on_area_cleared)
	_wave_manager.boss_spawned.connect(_on_boss_spawned)
	_wave_manager.timer_tick.connect(hud.on_timer_tick)
	_wave_manager.frenzy_started.connect(hud.on_frenzy_started)
	var radar: Node = load("res://scripts/EnemyRadar.gd").new()
	radar.name = "EnemyRadar"
	add_child(radar)
	_start_tutorial_if_needed()
	AudioManager.play_ambient()
	_run_start_time = Time.get_ticks_msec()
	_fragments_at_start = ProgressionManager.get_fragments()
	_wave_manager.enemy_killed.connect(func(): _enemies_killed += 1)
	call_deferred("_center_player")
	player.died.connect(_on_player_died)

func _center_player() -> void:
	var p := get_node_or_null("Player")
	if p:
		p.position = Vector2(0, 960)
	await get_tree().create_timer(0.6).timeout
	_wave_manager.start_next_wave()

func _start_tutorial_if_needed() -> void:
	if ProgressionManager.data.level > 1:
		return
	var tm: Node = load("res://scripts/TutorialManager.gd").new()
	tm.name = "TutorialManager"
	add_child(tm)
	tm.init(player)

func _on_wave_started(wave_number: int) -> void:
	print("Wave %d started" % wave_number)

func _on_wave_cleared(wave_number: int) -> void:
	if wave_number >= 3:
		return
	await get_tree().create_timer(2.0).timeout
	_wave_manager.start_next_wave()

func _on_player_died() -> void:
	var wave_reached: int = _wave_manager.current_wave if _wave_manager else 0
	await get_tree().create_timer(1.5).timeout
	_show_game_over_overlay(wave_reached)

func _show_game_over_overlay(wave_reached: int = 0) -> void:
	get_tree().paused = true
	var elapsed_sec: int = int((Time.get_ticks_msec() - _run_start_time) / 1000)
	var minutes: int = elapsed_sec / 60
	var seconds: int = elapsed_sec % 60
	var frags_earned := ProgressionManager.get_fragments() - _fragments_at_start

	var cl := CanvasLayer.new()
	cl.layer = 30
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(cl)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.modulate.a = 0.0
	cl.add_child(root)

	var bg := TextureRect.new()
	bg.texture = load("res://assets/game_over/background/Tela_Gameover_Sembotoes.png")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(320, 0)
	vbox.position += Vector2(0, 80)
	root.add_child(vbox)

	var stats: Array[String] = [
		"Inimigos derrotados: %d"  % _enemies_killed,
		"Fragmentos coletados: %d" % maxi(0, frags_earned),
		"Tempo: %dm %02ds"         % [minutes, seconds],
		"Onda alcançada: %d"       % wave_reached,
	]
	for s in stats:
		var lbl := Label.new()
		lbl.text = s
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.75))
		lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
		lbl.add_theme_constant_override("shadow_offset_x", 2)
		lbl.add_theme_constant_override("shadow_offset_y", 2)
		vbox.add_child(lbl)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	vbox.add_child(_make_go_button(
		"res://assets/game_over/buttons/try_again.png",
		func():
			ProgressionManager.reset_level()
			get_tree().paused = false
			get_tree().reload_current_scene()
	))
	vbox.add_child(_make_go_button(
		"res://assets/game_over/buttons/return_hub.png",
		func():
			get_tree().paused = false
			TransitionScreen.fade_to("res://scenes/Hub.tscn")
	))
	vbox.add_child(_make_go_button(
		"res://assets/game_over/buttons/main_menu.png",
		func():
			get_tree().paused = false
			TransitionScreen.fade_to("res://scenes/MainMenu.tscn")
	))

	var tween := root.create_tween()
	tween.tween_property(root, "modulate:a", 1.0, 0.6)

func _make_go_button(texture_path: String, callback: Callable) -> TextureButton:
	var btn := TextureButton.new()
	btn.texture_normal = load(texture_path)
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.custom_minimum_size = Vector2(280, 64)
	btn.pressed.connect(callback)
	btn.mouse_entered.connect(func():
		var t := btn.create_tween()
		t.tween_property(btn, "modulate", Color(1.3, 1.3, 1.3), 0.1)
	)
	btn.mouse_exited.connect(func():
		var t := btn.create_tween()
		t.tween_property(btn, "modulate", Color.WHITE, 0.1)
	)
	return btn

func _on_boss_spawned() -> void:
	hud.show_boss_label()

func _on_area_cleared() -> void:
	if player.is_dead:
		return
	ProgressionManager.advance_area()
	await get_tree().create_timer(1.5).timeout
	_spawn_exit_portal()

func _spawn_exit_portal() -> void:
	var portal := Area2D.new()
	portal.position = player.position + Vector2(80, 0)
	portal.z_index = 1
	add_child(portal)

	var spr := Sprite2D.new()
	spr.texture = load("res://assets/Free-Undead-Tileset-Top-Down-Pixel-Art/PNG/Objects_separately/Scull_door_shadow1.png")
	spr.scale = Vector2(1.4, 1.4)
	portal.add_child(spr)

	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 16
	particles.lifetime = 1.2
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 18.0
	particles.direction = Vector2(0, -1)
	particles.spread = 40.0
	particles.gravity = Vector2(0, -20)
	particles.initial_velocity_min = 8.0
	particles.initial_velocity_max = 20.0
	particles.color = Color(0.4, 0.0, 0.8, 0.7)
	particles.z_index = 2
	portal.add_child(particles)

	var shape := CircleShape2D.new()
	shape.radius = 32.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	portal.add_child(cs)

	portal.body_entered.connect(func(body):
		if body == player:
			portal.set_deferred("monitoring", false)
			TransitionScreen.fade_to("res://scenes/World.tscn")
	)

	# Animate portal appearing
	portal.scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(portal, "scale", Vector2.ONE, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if OS.is_debug_build():
		if event.is_action_pressed("debug_wave2"):
			_wave_manager.debug_skip_to_wave(2)
		elif event.is_action_pressed("debug_wave3"):
			_wave_manager.debug_skip_to_wave(3)
		elif event.is_action_pressed("debug_boss"):
			_wave_manager.debug_skip_to_wave(4)
		elif event.is_action_pressed("debug_next_area"):
			ProgressionManager.advance_area()
			TransitionScreen.fade_to("res://scenes/World.tscn")
		elif event.is_action_pressed("debug_prev_area"):
			ProgressionManager.data.current_area = max(1, ProgressionManager.data.current_area - 1)
			TransitionScreen.fade_to("res://scenes/World.tscn")

func _make_light_texture() -> Texture2D:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for y in range(128):
		for x in range(128):
			var d := Vector2(float(x) - 64.0, float(y) - 64.0).length() / 64.0
			var a := 0.0
			if d < 1.0:
				var t := 1.0 - d
				t = t * t * (3.0 - 2.0 * t)
				a = t * t
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(img)

func _setup_player_light() -> void:
	var area := ProgressionManager.get_current_area()
	var light := PointLight2D.new()
	light.texture = _light_texture
	light.texture_scale = 2.6
	light.energy = 1.5
	light.range_z_min = -10
	light.range_z_max = 100
	light.z_index = 5
	light.position = Vector2(0, -16)
	match area:
		1: light.color = Color(0.60, 0.88, 0.55)   # forest: warm green
		2: light.color = Color(0.90, 0.45, 0.20)   # cursed: amber-blood
		3: light.color = Color(0.50, 0.62, 1.00)   # undead: cold spectral blue
		_: light.color = Color(0.60, 0.75, 1.00)
	player.add_child(light)

func _setup_camera_limits() -> void:
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	# MapGenerator: 120×120 tiles, iso = ((col-row)*16, (col+row)*8)
	# Extremes: x in [-1904, 1904], y in [0, 1904]
	var pad := 96
	cam.limit_left   = -1904 - pad
	cam.limit_right  =  1904 + pad
	cam.limit_top    =     0 - pad
	cam.limit_bottom =  1904 + pad

func _setup_atmosphere() -> void:
	var area := ProgressionManager.get_current_area()

	# Void background — covers engine's gray beyond map tiles
	var void_layer := CanvasLayer.new()
	void_layer.layer = -10
	add_child(void_layer)
	var void_bg := ColorRect.new()
	void_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	match area:
		1: void_bg.color = Color(0.03, 0.05, 0.03)
		2: void_bg.color = Color(0.06, 0.02, 0.01)
		3: void_bg.color = Color(0.01, 0.01, 0.05)
		_: void_bg.color = Color(0.03, 0.04, 0.03)
	void_layer.add_child(void_bg)

	# CanvasModulate darkens the full scene so PointLight2D creates torch contrast
	var cm := CanvasModulate.new()
	match area:
		1: cm.color = Color(0.22, 0.26, 0.22)   # dark forest green
		2: cm.color = Color(0.26, 0.19, 0.16)   # dark blood-rust
		3: cm.color = Color(0.16, 0.18, 0.28)   # cold grave blue
		_: cm.color = Color(0.22, 0.24, 0.24)
	add_child(cm)

	var atm := CanvasLayer.new()
	atm.layer = 1

	# Phase-specific ambient wash
	var ambient := ColorRect.new()
	ambient.anchors_preset = Control.PRESET_FULL_RECT
	match area:
		1: ambient.color = Color(0.00, 0.03, 0.00, 0.18)  # Forest: deep moss green
		2: ambient.color = Color(0.05, 0.01, 0.00, 0.26)  # Cursed: sickly blood-dark
		3: ambient.color = Color(0.00, 0.00, 0.05, 0.22)  # Undead: cold grave blue
		_: ambient.color = Color(0.00, 0.02, 0.00, 0.20)
	atm.add_child(ambient)

	# Phase-specific vignette (heavier in cursed/undead)
	var vig_strength: float
	match area:
		1: vig_strength = 0.72
		2: vig_strength = 0.92
		3: vig_strength = 0.84
		_: vig_strength = 0.78
	var vignette_rect := ColorRect.new()
	vignette_rect.anchors_preset = Control.PRESET_FULL_RECT
	var vshader := Shader.new()
	vshader.code = (
		"shader_type canvas_item;\n"
		+ "uniform float strength : hint_range(0.0,1.5) = 0.78;\n"
		+ "void fragment() {\n"
		+ "\tvec2 uv = UV - vec2(0.5);\n"
		+ "\tfloat dist = length(uv) * 1.8;\n"
		+ "\tfloat v = smoothstep(0.25, 1.0, dist);\n"
		+ "\tCOLOR = vec4(0.0, 0.0, 0.0, v * strength);\n"
		+ "}"
	)
	var vmat := ShaderMaterial.new()
	vmat.shader = vshader
	vmat.set_shader_parameter("strength", vig_strength)
	vignette_rect.material = vmat
	atm.add_child(vignette_rect)
	add_child(atm)

	# Primary ground fog layer — phase-specific color and density
	var fog := CPUParticles2D.new()
	fog.emitting = true
	fog.one_shot = false
	fog.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fog.emission_rect_extents = Vector2(760.0, 300.0)
	fog.direction = Vector2(0.25, -1.0)
	fog.spread = 28.0
	fog.gravity = Vector2(0.0, -3.0)
	fog.z_index = -8
	match area:
		1:  # Forest: slow green wisps, moderate
			fog.amount = 65
			fog.lifetime = 7.0
			fog.initial_velocity_min = 4.0
			fog.initial_velocity_max = 11.0
			fog.scale_amount_min = 20.0
			fog.scale_amount_max = 40.0
			fog.color = Color(0.32, 0.52, 0.30, 0.08)
		2:  # Cursed: thick toxic brownish-red miasma
			fog.amount = 100
			fog.lifetime = 9.0
			fog.initial_velocity_min = 2.0
			fog.initial_velocity_max = 7.0
			fog.scale_amount_min = 26.0
			fog.scale_amount_max = 52.0
			fog.color = Color(0.52, 0.20, 0.10, 0.12)
			fog.direction = Vector2(0.10, -1.0)
		3:  # Undead: cold blue-grey spectral mist
			fog.amount = 80
			fog.lifetime = 10.0
			fog.initial_velocity_min = 3.0
			fog.initial_velocity_max = 8.0
			fog.scale_amount_min = 22.0
			fog.scale_amount_max = 46.0
			fog.color = Color(0.22, 0.30, 0.50, 0.09)
		_:
			fog.amount = 60
			fog.lifetime = 6.0
			fog.initial_velocity_min = 4.0
			fog.initial_velocity_max = 10.0
			fog.scale_amount_min = 18.0
			fog.scale_amount_max = 36.0
			fog.color = Color(0.45, 0.60, 0.45, 0.07)
	add_child(fog)

	# Phase 2: rising toxic spore particles (small, upward drift)
	if area == 2:
		var spores := CPUParticles2D.new()
		spores.emitting = true
		spores.amount = 40
		spores.lifetime = 4.5
		spores.one_shot = false
		spores.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		spores.emission_rect_extents = Vector2(800.0, 320.0)
		spores.direction = Vector2(0.05, -1.0)
		spores.spread = 12.0
		spores.gravity = Vector2(0.0, -10.0)
		spores.initial_velocity_min = 8.0
		spores.initial_velocity_max = 20.0
		spores.scale_amount_min = 2.0
		spores.scale_amount_max = 5.0
		spores.color = Color(0.62, 0.42, 0.08, 0.28)
		spores.z_index = 6
		add_child(spores)

	# Phase 3: spectral ember wisps (like Hub embers, blue-white)
	if area == 3:
		var wisps := CPUParticles2D.new()
		wisps.emitting = true
		wisps.amount = 35
		wisps.lifetime = 5.5
		wisps.one_shot = false
		wisps.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		wisps.emission_rect_extents = Vector2(800.0, 320.0)
		wisps.direction = Vector2(0.15, -1.0)
		wisps.spread = 22.0
		wisps.gravity = Vector2(0.0, -7.0)
		wisps.initial_velocity_min = 6.0
		wisps.initial_velocity_max = 16.0
		wisps.scale_amount_min = 2.0
		wisps.scale_amount_max = 5.0
		wisps.color = Color(0.38, 0.52, 0.92, 0.32)
		wisps.z_index = 6
		add_child(wisps)
