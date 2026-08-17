extends Node
## AudioManager
## Lightweight, pooled SFX playback + music bus control.
## Auto-mutes on focus loss when AppConfig.DEFAULT_MUTE_ON_FOCUS_LOST is set.

const SFX_BUS := "Master"
const MUSIC_BUS := "Music"

var master_volume_db: float = AppConfig.DEFAULT_MASTER_VOLUME_DB:
	set(v):
		master_volume_db = v
		var idx := AudioServer.get_bus_index(SFX_BUS)
		if idx != -1:
			AudioServer.set_bus_volume_db(idx, v)

var is_muted: bool = false:
	set(v):
		_muted = v
		is_muted = v
		var idx := AudioServer.get_bus_index(SFX_BUS)
		if idx != -1:
			AudioServer.set_bus_mute(idx, v)

var _muted: bool = false
var _sfx_pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0
const POOL_SIZE := 8
var _music_player: AudioStreamPlayer


func _ready() -> void:
	# Ensure buses exist (project.godot defines them via audio layout).
	_ensure_bus(SFX_BUS)
	_ensure_bus(MUSIC_BUS)

	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_sfx_pool.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)

	master_volume_db = AppConfig.DEFAULT_MASTER_VOLUME_DB


func _notification(what: int) -> void:
	# Mute audio when app is backgrounded on mobile (battery/accessibility).
	if not AppConfig.DEFAULT_MUTE_ON_FOCUS_LOST:
		return
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			AudioServer.set_bus_mute(AudioServer.get_bus_index(SFX_BUS), true)
		NOTIFICATION_APPLICATION_RESUMED:
			AudioServer.set_bus_mute(AudioServer.get_bus_index(SFX_BUS), false)


func play_sfx(stream: AudioStream, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null or _muted:
		return
	var p: AudioStreamPlayer = _sfx_pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


func play_music(stream: AudioStream) -> void:
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)