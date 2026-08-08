extends Node
# AudioManager — global music / ambient / sfx playback.
# Web rules: all players use PLAYBACK_TYPE_STREAM; music waits for the first
# user gesture before starting (browser autoplay policy).

const MAX_SFX_PLAYERS := 8

var _sfx_players: Array = []
var _sfx_index: int = 0
var _music_player: AudioStreamPlayer = null
var _ambient_player: AudioStreamPlayer = null
var _pending_music: AudioStream = null
var _pending_music_db: float = -6.0
var _music_started: bool = false
var _stream_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in MAX_SFX_PLAYERS:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		add_child(p)
		_sfx_players.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(_music_player)
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Master"
	_ambient_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	_ambient_player.volume_db = -14.0
	add_child(_ambient_player)

func _input(event: InputEvent) -> void:
	if _music_started:
		return
	var is_gesture: bool = false
	if event is InputEventMouseButton and event.pressed:
		is_gesture = true
	elif event is InputEventKey and event.pressed:
		is_gesture = true
	elif event is InputEventScreenTouch and event.pressed:
		is_gesture = true
	if is_gesture:
		_music_started = true
		if _pending_music != null:
			_start_music(_pending_music, _pending_music_db)
			_pending_music = null

func get_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]
	var s: AudioStream = load(path)
	if s is AudioStreamMP3:
		s.loop = false
	_stream_cache[path] = s
	return s

func play_sfx(path: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream: AudioStream = get_stream(path)
	if stream == null:
		return
	var p: AudioStreamPlayer = _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % MAX_SFX_PLAYERS
	p.stop()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()

func play_music(path: String, volume_db: float = -6.0) -> void:
	var stream: AudioStream = get_stream(path)
	if stream == null:
		return
	if stream is AudioStreamMP3:
		stream.loop = true
	if not _music_started:
		_pending_music = stream
		_pending_music_db = volume_db
		return
	_start_music(stream, volume_db)

func _start_music(stream: AudioStream, volume_db: float) -> void:
	if _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()
	_pending_music = null

func play_ambient(path: String, volume_db: float = -14.0) -> void:
	var stream: AudioStream = get_stream(path)
	if stream == null:
		return
	if stream is AudioStreamMP3:
		stream.loop = true
	if _ambient_player.stream == stream and _ambient_player.playing:
		return
	_ambient_player.stream = stream
	_ambient_player.volume_db = volume_db
	_ambient_player.play()

func stop_ambient() -> void:
	_ambient_player.stop()

func set_ambient_volume(volume_db: float) -> void:
	_ambient_player.volume_db = volume_db
