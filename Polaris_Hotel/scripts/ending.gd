extends Control
# Ending screen — good (polar night ends), bad (you become the rule-writer),
# under_bed (you looked). Click-through narration, then restart / menu.

const BG_EXTERIOR := "res://assets/textures/backgrounds/exterior.png"
const BG_ROOM := "res://assets/textures/backgrounds/room_301.png"
const TEX_HULDRA := "res://assets/sprites/characters/huldra_idle.png"
const SFX_STING := "res://assets/audio/music/jingle_game_over_rule_violation_sting.mp3"
const MUSIC := "res://assets/audio/music/music_exploration_polaris_theme.mp3"

var _lines: Array = []
var _idx: int = 0
var _label: Label = null
var _buttons: HBoxContainer = null
var _good: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_good = (GameState.ending == "good")

	var bg := TextureRect.new()
	if _good:
		bg.texture = load(BG_EXTERIOR)
	elif GameState.ending == "bad":
		bg.texture = load(BG_ROOM)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.05, 0.1, 0.25) if _good else Color(0, 0, 0.02, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if GameState.ending == "bad":
		var fig := TextureRect.new()
		fig.texture = load(TEX_HULDRA)
		fig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fig.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fig.size = Vector2(360, 360)
		fig.position = Vector2(760, 420)
		fig.modulate = Color(1, 1, 1, 0.65)
		fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fig)

	match GameState.ending:
		"good":
			_lines = TextDB.ENDING_GOOD
		"under_bed":
			_lines = TextDB.ENDING_UNDER_BED
		_:
			_lines = TextDB.ENDING_BAD

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 34)
	_label.add_theme_color_override("font_color", Color(0.9, 0.87, 0.78) if _good else Color(0.82, 0.78, 0.7))
	add_child(_label)
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_label.offset_left = -520
	_label.offset_right = 520
	_label.offset_top = -60
	_label.offset_bottom = 60

	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 40)
	_buttons.visible = false
	add_child(_buttons)
	_buttons.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_buttons.offset_top = -180
	_buttons.offset_bottom = -90
	_buttons.offset_left = -460
	_buttons.offset_right = 460

	var again := _make_button(TextDB.BTN_RESTART)
	_buttons.add_child(again)
	again.pressed.connect(func() -> void:
		LoadingScreen.preload_and_change_scene("res://scenes/game_world.tscn", 1.2))
	var menu := _make_button(TextDB.BTN_MENU)
	_buttons.add_child(menu)
	menu.pressed.connect(func() -> void:
		LoadingScreen.change_scene("res://scenes/main.tscn", 0.8))

	if _good:
		AudioManager.play_music(MUSIC, -10.0)
	else:
		AudioManager.play_sfx(SFX_STING, -4.0)

	_show_line()

func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 26)
	b.custom_minimum_size = Vector2(240, 72)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.07, 0.14, 0.92)
	normal.border_color = Color(0.72, 0.58, 0.3, 0.8)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	b.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(0.1, 0.13, 0.24, 0.95)
	b.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(0.16, 0.13, 0.07, 0.95)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	return b

func _show_line() -> void:
	if _idx < _lines.size():
		_label.text = String(_lines[_idx])
	else:
		_label.text = ""
		_buttons.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if _buttons.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_idx += 1
		_show_line()
	elif event is InputEventKey and event.pressed:
		_idx += 1
		_show_line()
