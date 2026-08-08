extends Control
# game_world — orchestrates rooms, input, modals, traps, endings.
# Interaction model: everything is proximity + [F]. The camera (T) is the
# anomaly tool: aim with the mouse, click to photograph. E = rules paper,
# TAB = hotel map, J = journal of photographed anomalies.

const MUSIC := "res://assets/audio/music/music_exploration_polaris_theme.mp3"
const AMBIENT := "res://assets/audio/ambient/ambient_abandoned_arctic_hotel_polar_night_hotel.mp3"
const SFX_CREAK := "res://assets/audio/sfx/environment/environment_door_creak.mp3"
const SFX_LANTERN_OUT := "res://assets/audio/sfx/environment/environment_lantern_out.mp3"
const SFX_DING := "res://assets/audio/sfx/environment/environment_elevator_ding.mp3"
const SFX_FIX := "res://assets/audio/sfx/ui/ui_anomaly_fix.mp3"
const SFX_PAPER := "res://assets/audio/sfx/ui/ui_paper_rustle.mp3"
const SFX_SLEEP := "res://assets/audio/sfx/ui/ui_sleep_fade.mp3"
const SFX_STING := "res://assets/audio/music/jingle_game_over_rule_violation_sting.mp3"
const SFX_STEP := "res://assets/audio/sfx/player/player_footstep.mp3"
const SFX_HEARTBEAT := "res://assets/audio/sfx/enemy/enemy_heartbeat.mp3"
const SFX_SHUTTER := "res://assets/audio/sfx/player/player_camera_shutter.mp3"
const SFX_CAMERA_UP := "res://assets/audio/sfx/ui/ui_camera_raise.mp3"
const VIGNETTE := "res://assets/textures/fx/vignette.png"
const TEX_FLASH := "res://assets/sprites/effects/camera_flash.png"

const WALK_SPEED := 278.0
const VERT_FACTOR := 0.55     # depth axis is foreshortened
const ACCEL := 1500.0
const AIM_RANGE := 130.0      # max click->anomaly-rect distance
const STAGE_TINTS := [
	Color(0.78, 0.8, 0.95),
	Color(0.62, 0.64, 0.85),
	Color(0.46, 0.47, 0.68),
	Color(0.3, 0.3, 0.5),
]

var room_view: RoomView = null
var subtitles: Subtitles = null
var hud: Hud = null
var director: EventDirector = null

var _room_container: Control = null
var _canvas_mod: CanvasModulate = null
var _modal_layer: CanvasLayer = null
var _camera_layer: CanvasLayer = null
var _fade: ColorRect = null
var _vignette_img: TextureRect = null
var _location_label: Label = null
var _prompt_label: Label = null
var _cross_h: ColorRect = null
var _cross_v: ColorRect = null

var _player_pos: Vector2 = Vector2.ZERO
var _vel: Vector2 = Vector2.ZERO
var _prompt_target: Hotspot = null
var _camera_on: bool = false
var _rules_dim: Control = null
var _rules_morning: bool = false
var _map_dim: Control = null
var _journal_dim: Control = null

var _blocking: int = 0
var _violating: bool = false
var _paused: bool = false
var _choice_open: bool = false
var _staring: bool = false
var _seventh_door_active: bool = false
var _blue_active: bool = false
var _loop_done_today: bool = false
var _huldra_done_today: bool = false
var _barked_rooms: Dictionary = {}
var _step_timer: float = 0.0
var _started: bool = false
var _last_room: String = "room_301"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_room_container = Control.new()
	_room_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_room_container)
	_room_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_canvas_mod = CanvasModulate.new()
	add_child(_canvas_mod)

	# vignette (its own canvas — not tinted by CanvasModulate)
	var vg_layer := CanvasLayer.new()
	vg_layer.layer = 2
	add_child(vg_layer)
	_vignette_img = TextureRect.new()
	_vignette_img.texture = load(VIGNETTE)
	_vignette_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette_img.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vg_layer.add_child(_vignette_img)
	_vignette_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# location label — always visible, own layer
	var loc_layer := CanvasLayer.new()
	loc_layer.layer = 3
	add_child(loc_layer)
	_location_label = Label.new()
	_location_label.add_theme_font_size_override("font_size", 22)
	_location_label.add_theme_color_override("font_color", Color(0.75, 0.72, 0.6, 0.9))
	_location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loc_layer.add_child(_location_label)
	_location_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_location_label.offset_left = -300
	_location_label.offset_right = 300
	_location_label.offset_top = 18

	# HUD layer (lanterns / day / key hint) + proximity prompt
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 4
	add_child(hud_layer)
	hud = Hud.new()
	hud_layer.add_child(hud)
	_prompt_label = Label.new()
	_prompt_label.add_theme_font_size_override("font_size", 23)
	_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68))
	_prompt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_prompt_label.add_theme_constant_override("shadow_offset_x", 2)
	_prompt_label.add_theme_constant_override("shadow_offset_y", 2)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_label.visible = false
	hud_layer.add_child(_prompt_label)
	_prompt_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_prompt_label.size = Vector2(360, 40)

	# subtitles layer
	var sub_layer := CanvasLayer.new()
	sub_layer.layer = 5
	add_child(sub_layer)
	subtitles = Subtitles.new()
	sub_layer.add_child(subtitles)

	# camera viewfinder layer (built lazily on first raise)
	_camera_layer = CanvasLayer.new()
	_camera_layer.layer = 6
	add_child(_camera_layer)
	_camera_layer.visible = false

	# modal layer (rule paper, choices, pause, map, journal)
	_modal_layer = CanvasLayer.new()
	_modal_layer.layer = 8
	add_child(_modal_layer)

	# fade layer
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 10
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	director = EventDirector.new()
	add_child(director)
	director.violation.connect(_on_violation)

	GameState.lanterns_changed.connect(_on_state_changed)
	GameState.day_changed.connect(_on_state_changed)

	AudioManager.play_music(MUSIC, -8.0)
	AudioManager.play_ambient(AMBIENT, -13.0)

	if SaveSystem.has_save() and SaveSystem.load_save():
		_apply_stage()
		call_deferred("start_day")
	else:
		GameState.new_game()
		_apply_stage()
		_run_intro()

func is_input_blocked() -> bool:
	return _blocking > 0 or _violating or _paused or _choice_open \
		or _map_dim != null or _journal_dim != null or _camera_on \
		or GameState.ending != "" or not _started

# --- intro ---------------------------------------------------------------------
func _run_intro() -> void:
	_blocking += 1
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 1)
	_modal_layer.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var lab := Label.new()
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.add_theme_font_size_override("font_size", 34)
	lab.add_theme_color_override("font_color", Color(0.85, 0.82, 0.72))
	overlay.add_child(lab)
	lab.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	lab.offset_left = -500
	lab.offset_right = 500
	lab.offset_top = -60
	lab.offset_bottom = 60
	var tip := Label.new()
	tip.text = TextDB.SUBTITLE_HINT
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.add_theme_font_size_override("font_size", 18)
	tip.add_theme_color_override("font_color", Color(0.5, 0.48, 0.4))
	overlay.add_child(tip)
	tip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	tip.offset_top = -60
	tip.offset_left = -80
	tip.offset_right = 80
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# NOTE: GDScript lambdas capture local primitives (int/bool) by value and
	# the mutation is lost between calls — keep mutable counters in an Array
	# cell (reference type) so clicks actually advance.
	var idx := [0]
	lab.text = TextDB.INTRO_LINES[0]
	_fade.modulate.a = 0.0
	_fade.color.a = 0.0
	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			idx[0] += 1
			AudioManager.play_sfx(SFX_PAPER, -8.0)
			if idx[0] >= TextDB.INTRO_LINES.size():
				overlay.queue_free()
				_blocking -= 1
				start_day()
			else:
				lab.text = TextDB.INTRO_LINES[idx[0]]
			overlay.accept_event())

# --- day flow -------------------------------------------------------------------
func start_day() -> void:
	_blocking += 1
	_exit_camera()
	_close_map()
	_close_journal()
	if _rules_dim != null:
		_close_rule_modal()
	_set_prompt(null)
	_staring = false
	_seventh_door_active = false
	_blue_active = false
	_loop_done_today = false
	_huldra_done_today = false
	_barked_rooms.clear()
	_barked_rooms["room_301"] = true  # morning narration covers the wake-up room
	GameState.current_room = "room_301"
	director.start_day(self)
	_apply_stage()
	_fade.color = Color(0, 0, 0, 1)
	_change_room("room_301", false)
	await _fade_to(0.0, 1.2)
	_blocking -= 1
	var day_name: String = String(TextDB.DAY_NAMES.get(GameState.day, ""))
	subtitles.say("%s. %s" % [day_name, TextDB.MORNING_LINE])
	if GameState.wet_day():
		subtitles.say(TextDB.MORNING_NOTE_WET)
	else:
		subtitles.say(TextDB.MORNING_NOTE)
	await get_tree().create_timer(1.0).timeout
	if GameState.ending == "":
		_open_rule_modal(true)

func _open_rule_modal(morning: bool) -> void:
	if _choice_open:
		return
	_choice_open = true
	_rules_morning = morning
	AudioManager.play_sfx(SFX_PAPER, -4.0)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	_modal_layer.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rules_dim = dim

	var paper := PanelContainer.new()
	var style: StyleBox = load("res://assets/ui/panel_rule.tres")
	if style != null:
		paper.add_theme_stylebox_override("panel", style)
	dim.add_child(paper)
	paper.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	paper.offset_left = -330
	paper.offset_right = 330
	paper.offset_top = -400
	paper.offset_bottom = 400

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	paper.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title := Label.new()
	var day_name: String = String(TextDB.DAY_NAMES.get(GameState.day, ""))
	title.text = "%s — 301호" % day_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.2, 0.13, 0.08))
	vbox.add_child(title)

	if GameState.wet_day():
		var wet := Label.new()
		wet.text = TextDB.RULE_WET
		wet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		wet.custom_minimum_size = Vector2(560, 0)
		wet.add_theme_font_size_override("font_size", 24)
		wet.add_theme_color_override("font_color", Color(0.3, 0.24, 0.2))
		vbox.add_child(wet)
	else:
		var head := Label.new()
		head.text = TextDB.RULE_HEADER
		head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		head.custom_minimum_size = Vector2(560, 0)
		head.add_theme_font_size_override("font_size", 24)
		head.add_theme_color_override("font_color", Color(0.22, 0.15, 0.1))
		vbox.add_child(head)
		for rid in GameState.rules_for_today():
			var l := Label.new()
			l.text = "· " + TextDB.rule_text(rid)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(560, 0)
			l.add_theme_font_size_override("font_size", 22)
			l.add_theme_color_override("font_color", Color(0.16, 0.11, 0.07))
			vbox.add_child(l)

	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 30)
	vbox.add_child(btns)

	if GameState.wet_day():
		var read_btn := _make_button(TextDB.RULE_WET_READ_CHOICE)
		btns.add_child(read_btn)
		read_btn.pressed.connect(func() -> void:
			_rules_dim = null
			dim.queue_free()
			_choice_open = false
			_on_violation("wet_read"))
		var down_btn := _make_button(TextDB.RULE_WET_PUT_DOWN)
		btns.add_child(down_btn)
		down_btn.pressed.connect(_close_rule_modal)
	else:
		var close_btn := _make_button(TextDB.BTN_CLOSE)
		btns.add_child(close_btn)
		close_btn.pressed.connect(_close_rule_modal)

func _close_rule_modal() -> void:
	if _rules_dim == null or not is_instance_valid(_rules_dim):
		_rules_dim = null
		return
	_rules_dim.queue_free()
	_rules_dim = null
	_choice_open = false
	GameState.note_read = true
	AudioManager.play_sfx(SFX_PAPER, -6.0)
	if _rules_morning and GameState.messy_day():
		subtitles.warn(TextDB.trap_line("messy_morning"))
	elif _rules_morning:
		subtitles.say(TextDB.sub("note_read"))

func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 24)
	b.custom_minimum_size = Vector2(200, 64)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.07, 0.14, 0.92)
	normal.border_color = Color(0.72, 0.58, 0.3, 0.8)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	b.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(0.1, 0.13, 0.24, 0.95)
	b.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(0.16, 0.13, 0.07, 0.95)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.8))
	return b

# --- room switching ---------------------------------------------------------------
func _change_room(room_id: String, with_sound: bool = true) -> void:
	if with_sound:
		AudioManager.play_sfx(SFX_CREAK, -6.0)
	GameState.current_room = room_id
	if room_view != null:
		room_view.queue_free()
	room_view = RoomView.new()
	_room_container.add_child(room_view)
	room_view.build(room_id, {"seventh_door": _seventh_door_active, "blue": _blue_active})
	_position_player_for_entry(room_id)
	_location_label.text = String(TextDB.LOCATION_NAMES.get(room_id, room_id))
	hud.refresh()
	_room_entry_bark(room_id)

func _position_player_for_entry(room_id: String) -> void:
	if room_view.player == null:
		return
	var band := RoomData.walk_band(room_id)
	var pos: Vector2 = RoomData.entry_for(room_id)
	match room_id:
		"corridor":
			if _last_room == "elevator_hall":
				pos = Vector2(1790.0, band.get_center().y)
			elif RoomData.CORRIDOR_DOORS.has(_last_room):
				pos = Vector2(float(RoomData.CORRIDOR_DOORS[_last_room]), band.get_center().y)
		"elevator_hall":
			if _last_room == "lobby":
				pos = Vector2(1180.0, band.get_center().y)
	pos.x = clampf(pos.x, band.position.x, band.end.x)
	pos.y = clampf(pos.y, band.position.y, band.end.y)
	_player_pos = pos
	_vel = Vector2.ZERO
	room_view.place_player(_player_pos)

func _go_to(room_id: String) -> void:
	if is_input_blocked():
		return
	# messy-morning: leaving 301 before fixing the bed is a violation
	if GameState.current_room == "room_301" and GameState.messy_day() and room_id != "room_301":
		_on_violation("messy_leave")
		return
	_blocking += 1
	_last_room = GameState.current_room
	_set_prompt(null)
	_exit_camera()
	_stop_stare()
	await _fade_to(1.0, 0.28)
	_change_room(room_id)
	await _fade_to(0.0, 0.28)
	_blocking -= 1

func _room_entry_bark(room_id: String) -> void:
	if _barked_rooms.has(room_id):
		return
	_barked_rooms[room_id] = true
	match room_id:
		"corridor":
			subtitles.say(TextDB.sub("enter_corridor"))
			_maybe_huldra()
			_maybe_missing_room_note()
		"room_301":
			subtitles.say(TextDB.sub("enter_301"))
			if GameState.lanterns == 1 and GameState.rng().randf() < 0.5:
				room_view.show_huldra(Vector2(980, 760), 5.0, false)
		"elevator_hall":
			subtitles.say(TextDB.sub("enter_elevator"))
		"lobby":
			subtitles.say(TextDB.sub("enter_lobby"))
		_:
			if TextDB.SUBS.has("enter_" + room_id.trim_prefix("room_")):
				subtitles.say(TextDB.sub("enter_" + room_id.trim_prefix("room_")))

func _maybe_huldra() -> void:
	var stage: int = GameState.fear_stage()
	if stage < 1 or _huldra_done_today:
		return
	var chance: float = 0.25 + 0.15 * stage
	if GameState.rng().randf() < chance:
		_huldra_done_today = true
		room_view.show_huldra(Vector2(150, 830), 5.5, true)
		subtitles.say(TextDB.sub("huldra_far"))

func _maybe_missing_room_note() -> void:
	if GameState.fear_stage() >= 3:
		subtitles.say(TextDB.sub("door_gone"))

# --- input -----------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	# toggles live above the block check so they can also CLOSE their overlay
	if event.is_action_pressed("toggle_rules"):
		if _rules_dim != null:
			_close_rule_modal()
		else:
			_close_map()
			_close_journal()
			if not is_input_blocked():
				_open_rule_modal(false)
		return
	if event.is_action_pressed("toggle_map"):
		if _map_dim != null:
			_close_map()
		else:
			_close_journal()
			if not is_input_blocked():
				_open_map_overlay()
		return
	if event.is_action_pressed("journal"):
		if _journal_dim != null:
			_close_journal()
		else:
			_close_map()
			if not is_input_blocked():
				_open_journal_overlay()
		return
	if event.is_action_pressed("camera_mode"):
		if _camera_on:
			_exit_camera()
		elif not is_input_blocked():
			_enter_camera()
		return
	if _camera_on and event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_photograph_at(get_global_mouse_position())
		return
	if _camera_on and event.is_action_pressed("interact"):
		# F works as a shutter button too — shoots at the crosshair.
		_photograph_at(get_global_mouse_position())
		return
	if event.is_action_pressed("pause_game"):
		_toggle_pause()
		return
	if is_input_blocked():
		return
	if event.is_action_pressed("interact"):
		if _prompt_target != null and is_instance_valid(_prompt_target):
			_activate_hotspot(_prompt_target)
		return
	if _staring and (event.is_action_pressed("move_left") or event.is_action_pressed("move_right") \
		or event.is_action_pressed("move_up") or event.is_action_pressed("move_down")):
		_stop_stare()

func _process(delta: float) -> void:
	if _camera_on:
		if room_view != null:
			_update_crosshair()
		return
	if is_input_blocked():
		_set_prompt(null)
		return
	if room_view == null or room_view.player == null:
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target := Vector2(dir.x * WALK_SPEED, dir.y * WALK_SPEED * VERT_FACTOR)
	_vel.x = move_toward(_vel.x, target.x, ACCEL * delta)
	_vel.y = move_toward(_vel.y, target.y, ACCEL * delta)
	var moving: bool = _vel.length() > 8.0
	if moving:
		_player_pos += _vel * delta
		var band := RoomData.walk_band(GameState.current_room)
		_player_pos.x = clampf(_player_pos.x, band.position.x, band.end.x)
		_player_pos.y = clampf(_player_pos.y, band.position.y, band.end.y)
		room_view.place_player(_player_pos)
		room_view.set_player_anim(_vel, true)
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = 0.46
			AudioManager.play_sfx(SFX_STEP, -12.0, GameState.rng().randf_range(0.9, 1.1))
	else:
		room_view.set_player_anim(Vector2.ZERO, false)
		_step_timer = 0.0
	_update_prompt()

# --- proximity prompt -------------------------------------------------------------
func _update_prompt() -> void:
	var best: Hotspot = null
	var best_d := INF
	for hs in room_view.hotspots():
		if hs.kind == "anomaly":  # camera-only; no proximity prompt
			continue
		var d: float = hs.distance_to_point(_player_pos)
		if d <= hs.reach() and d < best_d:
			best = hs
			best_d = d
	_set_prompt(best)
	if best != null:
		var top_y: float = room_view.player.position.y
		_prompt_label.position = Vector2(
			clampf(_player_pos.x - 180.0, 8.0, 1552.0), top_y - 46.0)

func _set_prompt(hs: Hotspot) -> void:
	if hs == _prompt_target:
		return
	_prompt_target = hs
	if hs == null:
		_prompt_label.visible = false
	else:
		_prompt_label.text = String(TextDB.PROMPT.get(hs.prompt_key(), TextDB.PROMPT["flavor"]))
		_prompt_label.visible = true

# --- hotspot actions (all via proximity + F) ---------------------------------------
func _activate_hotspot(hs: Hotspot) -> void:
	if is_input_blocked():
		return
	if _staring and hs.kind != "window":
		_stop_stare()
	match hs.kind:
		"flavor":
			subtitles.say(TextDB.flavor(String(hs.data.get("line", ""))))
		"sconce":
			subtitles.say(TextDB.flavor("sconce"))
		"elevator":
			AudioManager.play_sfx(SFX_DING, -4.0)
			_go_to("lobby")
		"exit":
			_on_exit(hs)
		"door":
			_enter_guest_room(String(hs.data.get("to", "")))
		"window":
			_on_window()
		"bed":
			_on_bed()
		"note":
			_open_rule_modal(false)
		"under_bed":
			_on_under_bed()
		"seventh_door":
			_on_violation("seventh_door")

func _on_exit(hs: Hotspot) -> void:
	# corridor east end: on bad nights the corridor folds back on itself
	if hs.hs_id == "exit_east" and GameState.fear_stage() >= 2 and not _loop_done_today:
		_loop_done_today = true
		var band := RoomData.walk_band("corridor")
		_player_pos = Vector2(220.0, band.get_center().y)
		_vel = Vector2.ZERO
		room_view.place_player(_player_pos)
		AudioManager.play_sfx(SFX_HEARTBEAT, -6.0)
		subtitles.say(TextDB.sub("loop_corridor"))
		return
	_go_to(String(hs.data.get("to", "corridor")))

func _enter_guest_room(room_id: String) -> void:
	if room_id == "room_305" and GameState.fear_stage() >= 3:
		subtitles.say(TextDB.sub("door_gone"))
		return
	_go_to(room_id)

func _on_window() -> void:
	if GameState.has_trap("window") and not GameState.wet_day():
		if not _staring:
			_staring = true
			director.window_stare(true)
			match GameState.current_room:
				"room_301":
					subtitles.say(TextDB.flavor("window_301"))
				"lobby":
					subtitles.say(TextDB.flavor("window_lobby"))
				_:
					subtitles.say(TextDB.flavor("window_guest"))
	else:
		match GameState.current_room:
			"room_301":
				subtitles.say(TextDB.flavor("window_301"))
			"lobby":
				subtitles.say(TextDB.flavor("window_lobby"))
			_:
				subtitles.say(TextDB.trap_line("window_safe"))

func _stop_stare() -> void:
	if _staring:
		_staring = false
		director.window_stare(false)

func _on_bed() -> void:
	if GameState.current_room != "room_301":
		subtitles.say(TextDB.flavor("bed_guest"))
		return
	if GameState.messy_day():
		GameState.messy_fixed = true
		room_view.clear_messy()
		AudioManager.play_sfx(SFX_FIX, -4.0)
		subtitles.say(TextDB.trap_line("messy_fixed"))
		return
	if GameState.all_fixed():
		show_choice(TextDB.sub("bed_sleep_ok"), TextDB.BTN_SLEEP, TextDB.BTN_STAY_UP, 30.0, _on_sleep_choice)
	else:
		subtitles.say(TextDB.sub("bed_sleep_left"))
		show_choice(TextDB.CHOICE_LINE_SLEEP, TextDB.BTN_SLEEP, TextDB.BTN_STAY_UP, 30.0, _on_sleep_choice)

func _on_sleep_choice(result: String) -> void:
	if result != "a":
		return
	_do_sleep()

func _do_sleep() -> void:
	_blocking += 1
	_stop_stare()
	director.stop()
	AudioManager.play_sfx(SFX_SLEEP, -4.0)
	await _fade_to(1.0, 1.4)
	var outcome: String = GameState.resolve_sleep()
	match outcome:
		"good_ending":
			_blocking -= 1
			_goto_ending()
		"bad_ending":
			_blocking -= 1
			_goto_ending()
		"next_day":
			subtitles.say(TextDB.sub("slept_clean"))
			SaveSystem.save()
			_blocking -= 1
			start_day()
		"repeat_day":
			AudioManager.play_sfx(SFX_LANTERN_OUT, -2.0)
			subtitles.warn(TextDB.sub("slept_dirty"))
			var line: String = String(TextDB.LANTERN_LOST_LINES.get(GameState.lanterns, ""))
			if line != "":
				subtitles.say(line)
			_apply_stage()
			SaveSystem.save()
			_blocking -= 1
			start_day()

func _on_under_bed() -> void:
	if GameState.lanterns <= 1:
		AudioManager.play_sfx(SFX_HEARTBEAT, -2.0)
		subtitles.warn(TextDB.UNDER_BED_END)
		GameState.ending = "under_bed"
		await get_tree().create_timer(2.2).timeout
		_goto_ending()
	else:
		subtitles.say(TextDB.sub("under_bed_safe"))

# --- camera --------------------------------------------------------------------------
func _enter_camera() -> void:
	if room_view == null or room_view.player == null:
		return
	_camera_on = true
	_stop_stare()
	_set_prompt(null)
	_vel = Vector2.ZERO
	room_view.set_player_anim(Vector2.ZERO, false)  # settle to idle behind the viewfinder
	AudioManager.play_sfx(SFX_CAMERA_UP, -6.0)
	if _cross_h == null:
		_build_viewfinder()
	_camera_layer.visible = true

func _exit_camera() -> void:
	if not _camera_on:
		return
	_camera_on = false
	_camera_layer.visible = false
	AudioManager.play_sfx(SFX_CAMERA_UP, -12.0, 0.85)

func _build_viewfinder() -> void:
	# dark bands around a 1280x720 center window
	var dim := Color(0, 0, 0, 0.55)
	var frame := Color(0.85, 0.8, 0.6, 0.45)
	var bands := [
		[0, 0, 1920, 180], [0, 900, 1920, 180],   # top / bottom
		[0, 180, 320, 720], [1600, 180, 320, 720]  # left / right
	]
	for b in bands:
		var r := ColorRect.new()
		r.color = dim
		r.position = Vector2(b[0], b[1])
		r.size = Vector2(b[2], b[3])
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_camera_layer.add_child(r)
	var edges := [
		[320, 178, 1280, 2], [320, 900, 1280, 2],
		[318, 180, 2, 720], [1600, 180, 2, 720]
	]
	for e in edges:
		var r := ColorRect.new()
		r.color = frame
		r.position = Vector2(e[0], e[1])
		r.size = Vector2(e[2], e[3])
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_camera_layer.add_child(r)
	_cross_h = ColorRect.new()
	_cross_h.color = Color(0.95, 0.9, 0.65, 0.9)
	_cross_h.size = Vector2(36, 2)
	_cross_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camera_layer.add_child(_cross_h)
	_cross_v = ColorRect.new()
	_cross_v.color = Color(0.95, 0.9, 0.65, 0.9)
	_cross_v.size = Vector2(2, 36)
	_cross_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camera_layer.add_child(_cross_v)
	var hint := Label.new()
	hint.text = TextDB.CAMERA_HINT
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color(0.85, 0.82, 0.68))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camera_layer.add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_left = -300
	hint.offset_right = 300
	hint.offset_top = -70
	hint.offset_bottom = -34

func _update_crosshair() -> void:
	var m := get_global_mouse_position()
	_cross_h.position = m + Vector2(-18, -1)
	_cross_v.position = m + Vector2(-1, -18)

# Distance from point p to rect r (0 when inside) — Rect2 has no distance_to.
func _rect_distance(r: Rect2, p: Vector2) -> float:
	var dx: float = maxf(r.position.x - p.x, p.x - r.end.x)
	var dy: float = maxf(r.position.y - p.y, p.y - r.end.y)
	return Vector2(maxf(dx, 0.0), maxf(dy, 0.0)).length()

func _photograph_at(m: Vector2) -> void:
	AudioManager.play_sfx(SFX_SHUTTER, -3.0)
	_camera_flash(m)
	var best: Hotspot = null
	var best_d := AIM_RANGE
	for hs in room_view.hotspots():
		if hs.kind != "anomaly":
			continue
		var d: float = _rect_distance(Rect2(hs.position, hs.size), m)
		if d < best_d:
			best = hs
			best_d = d
	if best == null:
		subtitles.say(TextDB.CAMERA_NOTHING)
		return
	# The camera is the ranged tool: aiming is enough, no proximity gate.
	_fix_anomaly(best)

func _camera_flash(at: Vector2) -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.8)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_layer.add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tw := flash.create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.3)
	tw.tween_callback(flash.queue_free)
	var burst := TextureRect.new()
	burst.texture = load(TEX_FLASH)
	burst.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	burst.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.size = Vector2(280, 280)
	burst.position = at - Vector2(140, 140)
	_modal_layer.add_child(burst)
	var tw2 := burst.create_tween()
	tw2.tween_property(burst, "modulate:a", 0.0, 0.45)
	tw2.tween_callback(burst.queue_free)

func _fix_anomaly(hs: Hotspot) -> void:
	var uid: String = String(hs.data.get("uid", ""))
	var a: Dictionary = GameState.fix_anomaly(uid)
	if a.is_empty():
		return
	room_view.remove_anomaly(uid)
	AudioManager.play_sfx(SFX_FIX, -5.0)
	var type: String = String(a.get("type", ""))
	GameState.discovered_log.append({
		"type": type,
		"room": String(a.get("room", GameState.current_room)),
		"day": GameState.day,
	})
	subtitles.say(String(TextDB.ANOMALY_FIX_LINES.get(type, "")))
	hud.refresh()
	SaveSystem.save()
	if GameState.all_fixed():
		subtitles.say(TextDB.sub("bed_sleep_ok"))

# --- map overlay (TAB) ---------------------------------------------------------------
func _open_map_overlay() -> void:
	AudioManager.play_sfx(SFX_PAPER, -8.0)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	_modal_layer.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_dim = dim
	var title := Label.new()
	title.text = TextDB.MAP_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.88, 0.84, 0.7))
	dim.add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -300
	title.offset_right = 300
	title.offset_top = 90
	var mm := Minimap.new()
	dim.add_child(mm)
	mm.size = Vector2(430, 210)
	mm.scale = Vector2(2.1, 2.1)
	mm.position = Vector2(960.0 - 430.0 * 2.1 * 0.5, 540.0 - 210.0 * 2.1 * 0.5)
	mm.set_current(GameState.current_room)
	mm.set_missing("room_305" if GameState.fear_stage() >= 3 else "")
	var close_btn := _make_button(TextDB.BTN_CLOSE)
	dim.add_child(close_btn)
	close_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	close_btn.offset_left = -100
	close_btn.offset_right = 100
	close_btn.offset_top = -110
	close_btn.offset_bottom = -46
	close_btn.pressed.connect(_close_map)

func _close_map() -> void:
	if _map_dim != null and is_instance_valid(_map_dim):
		_map_dim.queue_free()
		AudioManager.play_sfx(SFX_PAPER, -10.0)
	_map_dim = null

# --- journal overlay (J) -------------------------------------------------------------
func _open_journal_overlay() -> void:
	AudioManager.play_sfx(SFX_PAPER, -6.0)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	_modal_layer.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_journal_dim = dim

	var paper := PanelContainer.new()
	var style: StyleBox = load("res://assets/ui/panel_rule.tres")
	if style != null:
		paper.add_theme_stylebox_override("panel", style)
	dim.add_child(paper)
	paper.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	paper.offset_left = -330
	paper.offset_right = 330
	paper.offset_top = -360
	paper.offset_bottom = 360
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	paper.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = TextDB.JOURNAL_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.2, 0.13, 0.08))
	vbox.add_child(title)

	var log: Array = GameState.discovered_log
	if log.is_empty():
		var empty := Label.new()
		empty.text = TextDB.JOURNAL_EMPTY
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(560, 0)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 23)
		empty.add_theme_color_override("font_color", Color(0.3, 0.24, 0.18))
		vbox.add_child(empty)
	else:
		var seen: Dictionary = {}
		for e in log:
			seen[String(e.get("type", ""))] = true
		var count := Label.new()
		count.text = TextDB.JOURNAL_COUNT % seen.size()
		count.add_theme_font_size_override("font_size", 22)
		count.add_theme_color_override("font_color", Color(0.35, 0.26, 0.16))
		vbox.add_child(count)
		for e in log:
			var l := Label.new()
			var tname: String = String(TextDB.ANOMALY_NAMES.get(String(e.get("type", "")), "?"))
			var rname: String = String(TextDB.LOCATION_NAMES.get(String(e.get("room", "")), ""))
			var dname: String = String(TextDB.DAY_NAMES.get(int(e.get("day", 1)), ""))
			l.text = TextDB.JOURNAL_ENTRY % [tname, rname, dname]
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(560, 0)
			l.add_theme_font_size_override("font_size", 21)
			l.add_theme_color_override("font_color", Color(0.16, 0.11, 0.07))
			vbox.add_child(l)

	var close_btn := _make_button(TextDB.BTN_CLOSE)
	vbox.add_child(close_btn)
	close_btn.pressed.connect(_close_journal)

func _close_journal() -> void:
	if _journal_dim != null and is_instance_valid(_journal_dim):
		_journal_dim.queue_free()
		AudioManager.play_sfx(SFX_PAPER, -10.0)
	_journal_dim = null

# --- choice modal ------------------------------------------------------------------------
func show_choice(prompt: String, label_a: String, label_b: String, timeout: float, cb: Callable) -> void:
	if _choice_open:
		return
	_choice_open = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	_modal_layer.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.09, 0.94)
	style.border_color = Color(0.55, 0.45, 0.25, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", style)
	dim.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -360
	panel.offset_right = 360
	panel.offset_top = -140
	panel.offset_bottom = 140

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 26)
	panel.add_child(vbox)
	var lab := Label.new()
	lab.text = prompt
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab.custom_minimum_size = Vector2(620, 0)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", 26)
	lab.add_theme_color_override("font_color", Color(0.9, 0.86, 0.75))
	vbox.add_child(lab)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 40)
	vbox.add_child(btns)

	# Array cell — lambda local-capture is by-value, so a plain bool would
	# never stay true and finish could fire twice (button + timeout).
	var done := [false]
	var finish := func(result: String) -> void:
		if done[0]:
			return
		done[0] = true
		dim.queue_free()
		_choice_open = false
		cb.call(result)

	var btn_a := _make_button(label_a)
	btns.add_child(btn_a)
	btn_a.pressed.connect(func() -> void: finish.call("a"))
	var btn_b := _make_button(label_b)
	btns.add_child(btn_b)
	btn_b.pressed.connect(func() -> void: finish.call("b"))

	if timeout > 0.0:
		# A SceneTree timer outlives the modal. Once the player has answered,
		# finish() has already freed `dim`; on a scene change (menu/ending)
		# even `self` is gone. Calling finish() in either case makes the
		# engine log "Lambda capture at index N was freed" at call time —
		# the done-guard inside finish() can't prevent that, so the late
		# call must never happen. Only safe captures here (Array cell +
		# WeakRef are RefCounted and stay valid).
		var world_ref: WeakRef = weakref(self)
		get_tree().create_timer(timeout).timeout.connect(func() -> void:
			if done[0] or world_ref.get_ref() == null:
				return
			finish.call("timeout"))

# --- director-facing helpers -----------------------------------------------------------------
func show_shadow_figure(duration: float) -> void:
	if room_view != null:
		room_view.show_shadow_figure(duration)

func show_window_movement() -> void:
	if room_view != null:
		room_view.show_window_movement()

func show_seventh_door() -> void:
	_seventh_door_active = true
	if room_view != null and GameState.current_room == "corridor":
		room_view.show_seventh_door()

func set_blue_sconces(on: bool) -> void:
	_blue_active = on
	if room_view != null:
		room_view.set_blue_sconces(on)

# --- violation --------------------------------------------------------------------------------
func _on_violation(reason: String) -> void:
	if _violating or GameState.ending != "":
		return
	_violating = true
	_blocking += 1
	_exit_camera()
	_close_map()
	_close_journal()
	_stop_stare()
	director.stop()
	_set_prompt(null)
	AudioManager.play_sfx(SFX_STING, -2.0)
	_red_flash()
	subtitles.warn(TextDB.warn(reason))
	await get_tree().create_timer(2.4).timeout
	subtitles.warn(TextDB.VIOLATION_RESULT)
	await get_tree().create_timer(2.6).timeout
	await _fade_to(1.0, 0.8)
	GameState.apply_violation()
	SaveSystem.save()
	_apply_stage()
	_violating = false
	_blocking -= 1
	start_day()

func _red_flash() -> void:
	var flash := ColorRect.new()
	flash.color = Color(0.55, 0.05, 0.05, 0.0)
	_modal_layer.add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := flash.create_tween()
	tw.tween_property(flash, "color:a", 0.5, 0.18)
	tw.tween_property(flash, "color:a", 0.0, 1.2)
	tw.tween_callback(flash.queue_free)

# --- pause -------------------------------------------------------------------------------------
func _toggle_pause() -> void:
	if GameState.ending != "" or _violating or not _started:
		return
	if _paused:
		_close_pause()
		return
	_paused = true
	var dim := ColorRect.new()
	dim.name = "PauseOverlay"
	dim.color = Color(0, 0, 0, 0.7)
	dim.process_mode = Node.PROCESS_MODE_ALWAYS
	_modal_layer.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	dim.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.offset_left = -160
	vbox.offset_right = 160
	vbox.offset_top = -120
	vbox.offset_bottom = 120
	var title := Label.new()
	title.text = TextDB.sub("pause_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.85, 0.8, 0.68))
	vbox.add_child(title)
	var resume := _make_button(TextDB.BTN_RESUME)
	vbox.add_child(resume)
	resume.pressed.connect(func() -> void: _close_pause())
	var menu := _make_button(TextDB.BTN_MENU)
	vbox.add_child(menu)
	menu.pressed.connect(func() -> void:
		_close_pause()
		LoadingScreen.change_scene("res://scenes/main.tscn", 0.8))
	get_tree().paused = true

func _close_pause() -> void:
	get_tree().paused = false
	_paused = false
	var n: Node = _modal_layer.find_child("PauseOverlay", false, false)
	if n != null:
		n.queue_free()

# --- endings / state ----------------------------------------------------------------------------
func _goto_ending() -> void:
	SaveSystem.delete_save()
	LoadingScreen.change_scene("res://scenes/ui/ending.tscn", 1.0)

func _on_state_changed(_v: int) -> void:
	if is_instance_valid(hud):
		hud.refresh()
	_apply_stage()

func _apply_stage() -> void:
	var stage: int = GameState.fear_stage()
	_canvas_mod.color = STAGE_TINTS[clampi(stage, 0, 3)]
	_vignette_img.modulate.a = 0.55 + 0.12 * stage
	AudioManager.set_ambient_volume(-13.0 - 2.0 * stage)

func _fade_to(alpha: float, duration: float) -> void:
	var tw := _fade.create_tween()
	tw.tween_property(_fade, "color:a", alpha, duration)
	await tw.finished

# mark the game as actually started once the first day begins
func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		call_deferred("_mark_started")

func _mark_started() -> void:
	_started = true
