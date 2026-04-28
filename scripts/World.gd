extends Node2D

const UPGRADE_PANEL := preload("res://scenes/UpgradePanel.tscn")
const PAUSE_MENU    := preload("res://scenes/PauseMenu.tscn")

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD

var _wave_manager: Node

func _ready() -> void:
	hud.layer = 2
	player.add_to_group("player")
	player.health_changed.connect(hud.on_health_changed)
	player.died.connect(hud.on_player_died)
	add_child(UPGRADE_PANEL.instantiate())
	add_child(PAUSE_MENU.instantiate())
	_setup_atmosphere()

	_wave_manager = load("res://scripts/WaveManager.gd").new()
	_wave_manager.name = "WaveManager"
	add_child(_wave_manager)
	_wave_manager.init(self)
	_wave_manager.wave_cleared.connect(_on_wave_cleared)
	_wave_manager.wave_started.connect(_on_wave_started)
	_wave_manager.wave_started.connect(hud.on_wave_started)
	_wave_manager.start_next_wave()

func _on_wave_started(wave_number: int) -> void:
	print("Wave %d started" % wave_number)

func _on_wave_cleared(wave_number: int) -> void:
	print("Wave %d cleared!" % wave_number)
	await get_tree().create_timer(2.0).timeout
	_wave_manager.start_next_wave()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

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
