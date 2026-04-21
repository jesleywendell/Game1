extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	player.health_changed.connect(hud.on_health_changed)
	player.died.connect(hud.on_player_died)
