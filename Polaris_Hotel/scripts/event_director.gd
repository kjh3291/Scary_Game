class_name EventDirector
extends Node
# Schedules and runs the hotel's traps (each telegraphed by a morning rule),
# plus ambient dread events at higher fear stages. One active "watch" at a
# time; a watch either passes quietly or emits `violation`.

signal violation(reason: String)

var world: Node = null

var _fired: Dictionary = {}
var _schedule: Array = []       # [{trap, earliest, rooms}]
var _clock: float = 0.0
var _watch: Dictionary = {}     # active watch state
var _ambient_timer: float = 0.0
var _staring: bool = false
var _stare_time: float = 0.0
var _stare_warned: bool = false

const SND := {
	"whistle": "res://assets/audio/sfx/enemy/enemy_whistle_tune.mp3",
	"laugh": "res://assets/audio/sfx/enemy/enemy_child_laugh.mp3",
	"heartbeat": "res://assets/audio/sfx/enemy/enemy_heartbeat.mp3",
	"footstep": "res://assets/audio/sfx/player/player_footstep.mp3",
	"knock": "res://assets/audio/sfx/environment/environment_door_knock.mp3",
	"ding": "res://assets/audio/sfx/environment/environment_elevator_ding.mp3",
	"voice_name": "res://assets/audio/voice/nattmannen/voice_name_call.mp3",
	"voice_307": "res://assets/audio/voice/nattmannen/voice_knock_307.mp3",
}

func start_day(w: Node) -> void:
	world = w
	_clock = 0.0
	_fired.clear()
	_schedule.clear()
	_watch.clear()
	_staring = false
	_stare_time = 0.0
	_stare_warned = false
	_ambient_timer = 30.0
	var rng: RandomNumberGenerator = GameState.rng()
	var traps: Array = GameState.day_plan.get("traps", [])
	if traps.has("whistle"):
		_schedule.append({"trap": "whistle", "earliest": rng.randf_range(14.0, 26.0), "rooms": ["corridor", "elevator_hall", "lobby"]})
	if traps.has("name_call"):
		_schedule.append({"trap": "name_call", "earliest": rng.randf_range(22.0, 40.0), "rooms": ["corridor", "elevator_hall"]})
	if traps.has("knock307"):
		_schedule.append({"trap": "knock307", "earliest": rng.randf_range(16.0, 30.0), "rooms": ["room_301"]})
	if traps.has("blue_sconce"):
		_schedule.append({"trap": "blue_sconce", "earliest": rng.randf_range(10.0, 20.0), "rooms": ["corridor"]})
	if traps.has("ear_cover"):
		_schedule.append({"trap": "ear_cover", "earliest": rng.randf_range(25.0, 45.0), "rooms": ["room_301"]})
	# The seventh door appears on days rule r3 is posted (after the tutorial day).
	if GameState.day_plan.get("rules", []).has("r3") and GameState.day > 1:
		_schedule.append({"trap": "seventh_door", "earliest": rng.randf_range(4.0, 9.0), "rooms": ["corridor"]})

func stop() -> void:
	_schedule.clear()
	_watch.clear()
	_staring = false

func _process(delta: float) -> void:
	if world == null or GameState.ending != "":
		return
	if world.is_input_blocked():
		return
	_clock += delta
	_tick_schedule()
	_tick_watch(delta)
	_tick_stare(delta)
	_tick_ambient(delta)

# --- scheduling -------------------------------------------------------------
func _tick_schedule() -> void:
	if not _watch.is_empty():
		return  # one event at a time
	for item in _schedule:
		if bool(item.get("fired", false)):
			continue
		if _clock < float(item["earliest"]):
			continue
		if not item["rooms"].has(GameState.current_room):
			continue
		item["fired"] = true
		_fire(String(item["trap"]))

func _fire(trap: String) -> void:
	match trap:
		"whistle":
			AudioManager.play_sfx(SND["whistle"])
			world.show_shadow_figure(6.5)
			world.subtitles.warn(TextDB.trap_line("whistle_warn"))
			_watch = {"type": "whistle", "t": 0.0, "duration": 5.5, "grace": 0.6}
		"name_call":
			AudioManager.play_sfx(SND["voice_name"])
			world.subtitles.say(TextDB.trap_line("name_call_offer"))
			world.show_choice(TextDB.CHOICE_LINE_LOOK, TextDB.BTN_LOOK_BACK, TextDB.BTN_DONT_LOOK, 6.5, _on_name_call_choice)
		"knock307":
			AudioManager.play_sfx(SND["knock"])
			world.subtitles.say(TextDB.trap_line("knock_307"))
			await get_tree().create_timer(1.6).timeout
			if world == null:
				return
			AudioManager.play_sfx(SND["knock"])
			AudioManager.play_sfx(SND["voice_307"])
			world.show_choice(TextDB.CHOICE_LINE_307, TextDB.BTN_ANSWER, TextDB.BTN_IGNORE, 7.0, _on_knock_choice)
		"blue_sconce":
			world.set_blue_sconces(true)
			AudioManager.play_sfx(SND["heartbeat"], -4.0)
			world.subtitles.warn(TextDB.trap_line("blue_sconce_start"))
			_watch = {"type": "blue_sconce", "t": 0.0, "duration": 15.0}
		"ear_cover":
			AudioManager.play_sfx(SND["footstep"], -2.0, 0.8)
			world.subtitles.say(TextDB.trap_line("ear_sounds"))
			world.show_choice(TextDB.CHOICE_LINE_EARS, TextDB.BTN_COVER_EARS, TextDB.BTN_KEEP_LISTEN, 6.5, _on_ear_choice)
		"seventh_door":
			world.show_seventh_door()

# --- watches ----------------------------------------------------------------
func _tick_watch(delta: float) -> void:
	if _watch.is_empty():
		return
	_watch["t"] = float(_watch["t"]) + delta
	match String(_watch["type"]):
		"whistle":
			var t: float = _watch["t"]
			if t > float(_watch["grace"]):
				if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") \
					or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"):
					_watch.clear()
					violation.emit("whistle")
					return
			if t > float(_watch["duration"]):
				_watch.clear()
				world.subtitles.say(TextDB.trap_line("whistle_pass"))
		"blue_sconce":
			if GameState.current_room == "room_301":
				_watch.clear()
				world.set_blue_sconces(false)
				world.subtitles.say(TextDB.trap_line("blue_sconce_clear"))
				return
			if float(_watch["t"]) > float(_watch["duration"]):
				_watch.clear()
				world.set_blue_sconces(false)
				violation.emit("blue_sconce")

# --- window stare (passive trap) ---------------------------------------------
func window_stare(active: bool) -> void:
	if active and GameState.has_trap("window") and not bool(_fired.get("window_passed", false)):
		_staring = true
	else:
		_staring = false
		_stare_time = 0.0
		_stare_warned = false

func _tick_stare(delta: float) -> void:
	if not _staring:
		return
	_stare_time += delta
	if _stare_time > 3.0 and not _stare_warned:
		_stare_warned = true
		world.show_window_movement()
		world.subtitles.warn(TextDB.trap_line("window_stare_warn"))
	if _stare_time > 6.5:
		_staring = false
		violation.emit("window")

# --- choice callbacks ---------------------------------------------------------
func _on_name_call_choice(result: String) -> void:
	if result == "a":
		violation.emit("name_call")
	else:
		world.subtitles.say(TextDB.trap_line("name_call_pass"))

func _on_knock_choice(result: String) -> void:
	if result == "a":
		violation.emit("knock_307")
	else:
		world.subtitles.say(TextDB.trap_line("knock_pass"))

func _on_ear_choice(result: String) -> void:
	if result == "a":
		violation.emit("ear_cover")
	else:
		world.subtitles.say(TextDB.trap_line("ear_pass"))

# --- ambient dread (no fail state) ---------------------------------------------
func _tick_ambient(delta: float) -> void:
	var stage: int = GameState.fear_stage()
	if stage < 2:
		return
	_ambient_timer -= delta
	if _ambient_timer > 0.0:
		return
	_ambient_timer = GameState.rng().randf_range(35.0, 60.0)
	var pick: int = GameState.rng().randi_range(0, 2)
	match pick:
		0:
			AudioManager.play_sfx(SND["footstep"], -8.0, 0.7)
			world.subtitles.say(TextDB.sub("footsteps_far"))
		1:
			AudioManager.play_sfx(SND["ding"], -6.0)
			world.subtitles.say(TextDB.sub("elevator_ding_far"))
		2:
			AudioManager.play_sfx(SND["laugh"], -8.0)
			world.subtitles.say(TextDB.sub("child_laugh_far"))
