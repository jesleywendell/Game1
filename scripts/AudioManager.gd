extends Node

const SFX_PATHS := {
	"attack":        "res://assets/audio/jogador/attack/punch_2.wav",
	"enemy_attack":  "res://assets/audio/enemies/attack/slap.wav",
	"dash":          "res://assets/audio/sfx_dash.ogg",
	"damage_player": "res://assets/audio/sfx_damage_player.ogg",
	"player_die":    "res://assets/audio/sfx_player_die.ogg",
	"skill_q":       "res://assets/audio/sfx_skill_q.ogg",
	"skill_e":       "res://assets/audio/sfx_skill_e.ogg",
	"hp_drain":      "res://assets/audio/sfx_hp_drain.ogg",
	"enemy_die":     "res://assets/audio/sfx_enemy_die.ogg",
	"boss_phase2":   "res://assets/audio/sfx_boss_phase2.ogg",
}
const BTN_SFX_PATH    := "res://assets/audio/botoes/hover_click/sound_ex_machina_Buttons-Stone-Button.wav"
const AMBIENT_PATH    := "res://assets/audio/ambient_forest.ogg"
const WAVE_MUSIC_PATH := "res://assets/audio/waves/LVS04_10_Battlefield_bpm180_loop.wav"
const BOSS_MUSIC_PATH := "res://assets/audio/waves/wave_boss/01-DavidKBD-Purgatory-Pack-Purgatory.wav"

var _players: Dictionary = {}
var _ambient: AudioStreamPlayer
var _btn_hover: AudioStreamPlayer
var _btn_click: AudioStreamPlayer
var _music: AudioStreamPlayer
var _current_music_path := ""

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

	var btn_stream: AudioStream = load(BTN_SFX_PATH) if ResourceLoader.exists(BTN_SFX_PATH) else null
	_btn_hover = AudioStreamPlayer.new()
	_btn_hover.name = "btn_hover"
	_btn_hover.stream = btn_stream
	_btn_hover.volume_db = -12.0
	add_child(_btn_hover)

	_btn_click = AudioStreamPlayer.new()
	_btn_click.name = "btn_click"
	_btn_click.stream = btn_stream
	_btn_click.volume_db = -6.0
	add_child(_btn_click)

	_music = AudioStreamPlayer.new()
	_music.name = "music"
	_music.volume_db = -8.0
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music)

func play_sfx(sfx_key: String) -> void:
	if not _players.has(sfx_key):
		return
	var p: AudioStreamPlayer = _players[sfx_key]
	if p.stream == null:
		return
	p.stop()
	p.play()

func play_btn_hover() -> void:
	if _btn_hover.stream == null:
		return
	_btn_hover.stop()
	_btn_hover.play()

func play_btn_click() -> void:
	if _btn_click.stream == null:
		return
	_btn_click.stop()
	_btn_click.play()

func play_ambient() -> void:
	if _ambient.stream == null:
		return
	if not _ambient.playing:
		_ambient.play()

func stop_ambient() -> void:
	_ambient.stop()

func play_wave_music() -> void:
	_play_music(WAVE_MUSIC_PATH)

func play_boss_music() -> void:
	_play_music(BOSS_MUSIC_PATH)

func stop_music() -> void:
	_music.stop()
	_current_music_path = ""

func _play_music(path: String) -> void:
	if _current_music_path == path and _music.playing:
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	_music.stop()
	_current_music_path = path
	if stream is AudioStreamWAV:
		var wav := (stream as AudioStreamWAV).duplicate() as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_music.stream = wav
	else:
		_music.stream = stream
	_music.play()
