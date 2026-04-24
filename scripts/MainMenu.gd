extends Node2D

@onready var btn_iniciar: Button = $CanvasLayer/ButtonsContainer/BtnIniciar
@onready var btn_opcoes: Button = $CanvasLayer/ButtonsContainer/BtnOpcoes
@onready var btn_sair: Button = $CanvasLayer/ButtonsContainer/BtnSair
@onready var options_panel: Panel = $CanvasLayer/OptionsPanel
@onready var btn_fechar: Button = $CanvasLayer/OptionsPanel/VBox/BtnFechar
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect

func _ready() -> void:
	btn_iniciar.activated.connect(_start_game)
	btn_opcoes.activated.connect(_open_options)
	btn_sair.activated.connect(get_tree().quit)
	btn_fechar.activated.connect(_close_options)
	_fade_in()

func _fade_in() -> void:
	fade_rect.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.5)

func _start_game() -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.4)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/World.tscn"))

func _open_options() -> void:
	options_panel.show()

func _close_options() -> void:
	options_panel.hide()
