extends Node2D

const UPGRADE_PANEL := preload("res://scenes/UpgradePanel.tscn")
const PAUSE_MENU    := preload("res://scenes/PauseMenu.tscn")

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD

var _wave_manager: Node
var _enemies_killed: int = 0
var _run_start_time: int = 0
var _fragments_at_start: int = 0

func _ready() -> void:
	hud.layer = 2
	player.add_to_group("player")
	player.health_changed.connect(hud.on_health_changed)
	player.died.connect(hud.on_player_died)
	add_child(PAUSE_MENU.instantiate())
	add_child(UPGRADE_PANEL.instantiate())
	_setup_atmosphere()

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
	_wave_manager.start_next_wave()
	_start_tutorial_if_needed()
	AudioManager.play_ambient()
	_run_start_time = Time.get_ticks_msec()
	_fragments_at_start = ProgressionManager.get_fragments()
	_wave_manager.enemy_killed.connect(func(): _enemies_killed += 1)
	player.died.connect(_on_player_died)

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
	await get_tree().create_timer(1.5).timeout
	_show_game_over_overlay()

func _show_game_over_overlay() -> void:
	get_tree().paused = true
	var elapsed_sec: int = int((Time.get_ticks_msec() - _run_start_time) / 1000)
	var minutes: int = elapsed_sec / 60
	var seconds: int = elapsed_sec % 60
	var frags_earned := ProgressionManager.get_fragments() - _fragments_at_start

	var cl := CanvasLayer.new()
	cl.layer = 30
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(cl)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.88)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	cl.add_child(bg)

	var root_ctrl := Control.new()
	root_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(root_ctrl)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(480, 0)
	root_ctrl.add_child(vbox)

	var title := Label.new()
	title.text = "OATHBREAKER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.75, 0.08, 0.08, 1.0))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "A redenção exige sacrifício"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.65, 0.55, 0.55, 1.0))
	vbox.add_child(sub)

	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(360, 12)
	vbox.add_child(sep)

	var stats: Array[String] = [
		"Inimigos derrotados: %d"   % _enemies_killed,
		"Fragmentos coletados: %d"  % maxi(0, frags_earned),
		"Tempo: %dm %02ds"          % [minutes, seconds],
		"Onda alcançada: %d"        % _wave_manager.current_wave,
	]
	for s in stats:
		var lbl := Label.new()
		lbl.text = s
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
		vbox.add_child(lbl)

	var sep2 := HSeparator.new()
	sep2.custom_minimum_size = Vector2(360, 12)
	vbox.add_child(sep2)

	var btn_retry := Button.new()
	btn_retry.text = "Tentar Novamente"
	btn_retry.add_theme_font_size_override("font_size", 22)
	btn_retry.custom_minimum_size = Vector2(260, 50)
	btn_retry.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	vbox.add_child(btn_retry)

	var btn_hub := Button.new()
	btn_hub.text = "Retornar ao Hub"
	btn_hub.add_theme_font_size_override("font_size", 22)
	btn_hub.custom_minimum_size = Vector2(260, 50)
	btn_hub.pressed.connect(func():
		get_tree().paused = false
		TransitionScreen.fade_to("res://scenes/Hub.tscn")
	)
	vbox.add_child(btn_hub)

	var btn_menu := Button.new()
	btn_menu.text = "Menu Principal"
	btn_menu.add_theme_font_size_override("font_size", 22)
	btn_menu.custom_minimum_size = Vector2(260, 50)
	btn_menu.pressed.connect(func():
		get_tree().paused = false
		TransitionScreen.fade_to("res://scenes/MainMenu.tscn")
	)
	vbox.add_child(btn_menu)

func _on_boss_spawned() -> void:
	hud.show_boss_label()

func _on_area_cleared() -> void:
	await get_tree().create_timer(2.5).timeout
	_show_victory_overlay()

func _show_victory_overlay() -> void:
	get_tree().paused = true
	var cl := CanvasLayer.new()
	cl.layer = 30
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(cl)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.75)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	cl.add_child(bg)

	var root_ctrl := Control.new()
	root_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(root_ctrl)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(480, 0)
	root_ctrl.add_child(vbox)

	var title := Label.new()
	title.text = "ÁREA 1 VENCIDA"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Coxinha Knight derrotado"
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	var btn := Button.new()
	btn.text = "Menu Principal"
	btn.add_theme_font_size_override("font_size", 24)
	btn.custom_minimum_size = Vector2(220, 52)
	btn.pressed.connect(func():
		get_tree().paused = false
		TransitionScreen.fade_to("res://scenes/MainMenu.tscn")
	)
	vbox.add_child(btn)

	var btn_hub := Button.new()
	btn_hub.text = "Retornar ao Hub"
	btn_hub.add_theme_font_size_override("font_size", 22)
	btn_hub.custom_minimum_size = Vector2(260, 50)
	btn_hub.pressed.connect(func():
		get_tree().paused = false
		TransitionScreen.fade_to("res://scenes/Hub.tscn")
	)
	vbox.add_child(btn_hub)

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

func _setup_atmosphere() -> void:
	var atm := CanvasLayer.new()
	atm.layer = 1
	var ambient := ColorRect.new()
	ambient.color = Color(0.0, 0.02, 0.0, 0.20)
	ambient.anchors_preset = Control.PRESET_FULL_RECT
	atm.add_child(ambient)
	var vignette_rect := ColorRect.new()
	vignette_rect.anchors_preset = Control.PRESET_FULL_RECT
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv) * 1.8;
	float v = smoothstep(0.25, 1.0, dist);
	COLOR = vec4(0.0, 0.0, 0.0, v * 0.78);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	vignette_rect.material = mat
	atm.add_child(vignette_rect)
	add_child(atm)
	var fog := CPUParticles2D.new()
	fog.emitting = true
	fog.amount = 60
	fog.lifetime = 6.0
	fog.one_shot = false
	fog.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fog.emission_rect_extents = Vector2(700.0, 280.0)
	fog.direction = Vector2(0.3, -1.0)
	fog.spread = 30.0
	fog.gravity = Vector2(0.0, -4.0)
	fog.initial_velocity_min = 4.0
	fog.initial_velocity_max = 10.0
	fog.scale_amount_min = 18.0
	fog.scale_amount_max = 36.0
	fog.color = Color(0.45, 0.6, 0.45, 0.07)
	fog.z_index = 5
	add_child(fog)
