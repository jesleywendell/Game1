extends Node2D

@onready var btn_iniciar: GameMenuButton = $CanvasLayer/ButtonContainer/BtnIniciar
@onready var btn_creditos: GameMenuButton = $CanvasLayer/ButtonContainer/BtnCreditos
@onready var btn_sair: GameMenuButton = $CanvasLayer/ButtonContainer/BtnSair
@onready var modal_overlay: Control = $CanvasLayer/ModalOverlay
@onready var modal_panel: PanelContainer = $CanvasLayer/ModalOverlay/ModalPanel
@onready var modal_title: Label = $CanvasLayer/ModalOverlay/ModalPanel/VBox/TitleLabel
@onready var modal_message: Label = $CanvasLayer/ModalOverlay/ModalPanel/VBox/MessageLabel
@onready var modal_bg: ColorRect = $CanvasLayer/ModalOverlay/ModalBg
@onready var btn_fechar: Button = $CanvasLayer/ModalOverlay/ModalPanel/VBox/BtnFechar
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect

func _ready() -> void:
	get_node("CanvasLayer/ButtonContainer/BtnConfiguracoes").queue_free()
	btn_iniciar.activated.connect(_start_game)
	btn_creditos.activated.connect(func(): get_tree().change_scene_to_file("res://scenes/Credits.tscn"))
	btn_sair.activated.connect(func(): get_tree().quit())
	btn_fechar.pressed.connect(_close_modal)
	modal_bg.gui_input.connect(_on_modal_bg_input)
	modal_overlay.hide()
	_fade_in()
	_play_music()

func _play_music() -> void:
	const MUSIC_PATH := "res://assets/audio/mainMenu/gregoryallenbrown-creeping-dark-ambience-189391.wav"
	if not ResourceLoader.exists(MUSIC_PATH):
		push_warning("MainMenu: música não encontrada em " + MUSIC_PATH)
		return
	var player := AudioStreamPlayer.new()
	player.stream = load(MUSIC_PATH)
	player.volume_db = -6.0
	player.bus = "Master"
	add_child(player)
	player.finished.connect(player.play)
	player.play()

func _on_modal_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_modal()

func _fade_in() -> void:
	fade_rect.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.6)

func _start_game() -> void:
	TransitionScreen.fade_to("res://scenes/Hub.tscn")

func _open_modal(title: String, message: String) -> void:
	modal_title.text = title
	modal_message.text = message
	modal_overlay.show()
	await get_tree().process_frame
	modal_panel.pivot_offset = modal_panel.size / 2.0
	modal_panel.scale = Vector2(0.88, 0.88)
	modal_panel.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(modal_panel, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(modal_panel, "modulate:a", 1.0, 0.18)

func _close_modal() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(modal_panel, "scale", Vector2(0.92, 0.92), 0.14).set_ease(Tween.EASE_IN)
	tween.tween_property(modal_panel, "modulate:a", 0.0, 0.12)
	await tween.finished
	modal_overlay.hide()
	modal_panel.scale = Vector2(1.0, 1.0)
	modal_panel.modulate.a = 1.0
