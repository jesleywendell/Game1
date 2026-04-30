extends Node

const SFX_PATHS := {
	"attack":        "res://assets/audio/sfx_attack.ogg",
	"dash":          "res://assets/audio/sfx_dash.ogg",
	"damage_player": "res://assets/audio/sfx_damage_player.ogg",
	"player_die":    "res://assets/audio/sfx_player_die.ogg",
	"skill_q":       "res://assets/audio/sfx_skill_q.ogg",
	"skill_e":       "res://assets/audio/sfx_skill_e.ogg",
	"hp_drain":      "res://assets/audio/sfx_hp_drain.ogg",
	"enemy_die":     "res://assets/audio/sfx_enemy_die.ogg",
	"boss_phase2":   "res://assets/audio/sfx_boss_phase2.ogg",
}
const AMBIENT_PATH := "res://assets/audio/ambient_forest.ogg"

var _players: Dictionary = {}
var _ambient: AudioStreamPlayer

func _ready() -> void:
	for key in SFX_PATHS:
		var player := AudioStreamPlayer.new()
		if ResourceLoader.exists(SFX_PATHS[key]):
			player.stream = load(SFX_PATHS[key])
		player.name = "sfx_" + key
		add_child(player)
		_players[key] = player

	_ambient = AudioStreamPlayer.new()
	_ambient.name = "ambient"
	_ambient.volume_db = -10.0
	if ResourceLoader.exists(AMBIENT_PATH):
		_ambient.stream = load(AMBIENT_PATH)
	add_child(_ambient)

func play_sfx(sfx_key: String) -> void:
	if not _players.has(sfx_key):
		return
	var p: AudioStreamPlayer = _players[sfx_key]
	if p.stream == null:
		return
	p.stop()
	p.play()

func play_ambient() -> void:
	if _ambient.stream == null:
		return
	if not _ambient.playing:
		_ambient.play()

func stop_ambient() -> void:
	_ambient.stop()
