extends Node2D

@onready var btn_iniciar: GameMenuButton = $CanvasLayer/BtnIniciar
@onready var btn_configuracoes: GameMenuButton = $CanvasLayer/BtnConfiguracoes
@onready var btn_creditos: GameMenuButton = $CanvasLayer/BtnCreditos
@onready var btn_sair: GameMenuButton = $CanvasLayer/BtnSair
@onready var info_panel: Panel = $CanvasLayer/InfoPanel
@onready var info_label: Label = $CanvasLayer/InfoPanel/VBox/Label
@onready var btn_fechar: GameMenuButton = $CanvasLayer/InfoPanel/VBox/BtnFechar
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect

func _ready() -> void:
	btn_iniciar.activated.connect(_start_game)
	btn_configuracoes.activated.connect(func(): _open_info("Configuracoes\n- Em breve -"))
	btn_creditos.activated.connect(func(): _open_info("Creditos\n- Em breve -"))
	btn_sair.activated.connect(func(): get_tree().quit())
	btn_fechar.activated.connect(_close_info)
	_fade_in()

func _fade_in() -> void:
	fade_rect.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.5)

func _start_game() -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.4)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/World.tscn"))

func _open_info(text: String) -> void:
	info_label.text = text
	info_panel.show()

func _close_info() -> void:
	info_panel.hide()
