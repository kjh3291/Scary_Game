# tesana:custom-main-menu
extends Control

const TESANA_QUIT_URL := "https://tesana.ai/quit"
const PLAY_TARGET_SCENE := "res://scenes/game_world.tscn"
const INTRO_SCENE := "res://scenes/ui/intro.tscn"
const CONFIG_PATH := "user://settings.cfg"

# play/quit 버튼은 이미지 스타일박스, settings는 텍스트 버튼으로 별도 처리
const BUTTON_IDS: PackedStringArray = ["play", "settings", "quit"]
const BUTTON_STYLEBOXES: PackedStringArray = [
	"res://assets/ui/btn_play.tres",
	"",
	"res://assets/ui/btn_quit.tres",
]

const BG_CANDIDATES: PackedStringArray = [
	"res://assets/ui/title_poster.webp",
	"res://assets/ui/title_poster.png",
	"res://assets/textures/backgrounds/menu_background.png",
	"res://assets/textures/backgrounds/menu_bg.png",
	"res://assets/ui/menu_background.png",
]
const CLICK_SFX_CANDIDATES: PackedStringArray = [
	"res://assets/audio/sfx/ui/ui_menu_click.mp3",
	"res://assets/audio/sfx/ui/ui_button_click.mp3",
	"res://assets/audio/sfx/ui/ui_click.mp3",
]

var _click_sfx_stream: AudioStream = null
var _wordmark: TextureRect = null


func _ready() -> void:
	_load_settings()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if ResourceLoader.exists("res://assets/ui/theme.tres"):
		theme = load("res://assets/ui/theme.tres") as Theme

	var sfx_path := _first_existing(CLICK_SFX_CANDIDATES)
	if sfx_path != "":
		_click_sfx_stream = load(sfx_path) as AudioStream

	_build_background()
	_build_wordmark()
	_build_buttons()
	_build_save_banner()


func _build_save_banner() -> void:
	var info := SaveSystem.peek()
	if info.is_empty():
		return
	var lbl := Label.new()
	lbl.text = "저장된 게임: %d일차  ·  랜턴 %d개" % [info.get("day", 1), info.get("lanterns", 3)]
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.62, 0.58, 0.44, 0.72))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	lbl.offset_left = -300; lbl.offset_right = 300
	lbl.offset_top = -58;   lbl.offset_bottom = -18


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		var v: float = cfg.get_value("audio", "master_volume", 0.8)
		var db := linear_to_db(v) if v > 0.001 else -80.0
		AudioServer.set_bus_volume_db(0, db)


func _first_existing(paths: PackedStringArray) -> String:
	for p in paths:
		if ResourceLoader.exists(p):
			return p
	return ""


func _build_background() -> void:
	var bg_path := _first_existing(BG_CANDIDATES)
	if bg_path != "":
		var bg := TextureRect.new()
		bg.texture = load(bg_path)
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		var solid := ColorRect.new()
		solid.color = Color(0.08, 0.08, 0.10, 1.0)
		solid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(solid)
		solid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vignette := ColorRect.new()
	vignette.color = Color(0, 0, 0, 0.35)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_wordmark() -> void:
	if not ResourceLoader.exists("res://assets/ui/wordmark_title.png"):
		return
	_wordmark = TextureRect.new()
	_wordmark.texture = load("res://assets/ui/wordmark_title.png")
	_wordmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_wordmark.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_wordmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_wordmark)
	_wordmark.anchor_left = 0.5
	_wordmark.anchor_right = 0.5
	_wordmark.anchor_top = 0.0
	_wordmark.anchor_bottom = 0.0
	_wordmark.offset_left = -450
	_wordmark.offset_right = 450
	_wordmark.offset_top = 80
	_wordmark.offset_bottom = 380


func _build_buttons() -> void:
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	center.add_child(vbox)

	if _wordmark != null:
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 240)
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(spacer)

	for i in BUTTON_IDS.size():
		var btn := _make_button(BUTTON_IDS[i], BUTTON_STYLEBOXES[i])
		vbox.add_child(btn)


func _make_button(id: String, stylebox_path: String) -> Button:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE

	if stylebox_path != "" and ResourceLoader.exists(stylebox_path):
		# 이미지 기반 버튼 (play, quit)
		btn.custom_minimum_size = Vector2(360, 110)
		btn.text = ""
		var sb := load(stylebox_path) as StyleBox
		if sb:
			btn.add_theme_stylebox_override("normal", sb)
			btn.add_theme_stylebox_override("hover", sb)
			btn.add_theme_stylebox_override("pressed", sb)
			btn.add_theme_stylebox_override("focus", sb)
			btn.add_theme_stylebox_override("disabled", sb)
	else:
		# 텍스트 기반 버튼 (settings 등)
		btn.custom_minimum_size = Vector2(360, 80)
		btn.text = _button_label(id)
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_color_override("font_color", Color(0.88, 0.82, 0.65))
		var sb_n := _make_flat_sb(Color(0.12, 0.10, 0.08, 0.88), Color(0.42, 0.36, 0.24, 0.85))
		var sb_h := _make_flat_sb(Color(0.22, 0.19, 0.14, 1.0),  Color(0.62, 0.52, 0.32, 1.0))
		btn.add_theme_stylebox_override("normal",   sb_n)
		btn.add_theme_stylebox_override("hover",    sb_h)
		btn.add_theme_stylebox_override("pressed",  sb_h)
		btn.add_theme_stylebox_override("focus",    sb_n)
		btn.add_theme_stylebox_override("disabled", sb_n)

	btn.mouse_entered.connect(_on_button_hover.bind(btn, true))
	btn.mouse_exited.connect(_on_button_hover.bind(btn, false))
	btn.pressed.connect(_on_button_pressed.bind(id))
	return btn


func _button_label(id: String) -> String:
	match id:
		"settings": return "설정 / Settings"
		"credits":  return "크레딧"
		"back":     return "돌아가기"
		_:          return id.capitalize()


func _make_flat_sb(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


func _on_button_hover(btn: Button, entering: bool) -> void:
	var target := Color(1.10, 1.10, 1.10, 1.0) if entering else Color(1.0, 1.0, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(btn, "modulate", target, 0.08)


func _on_button_pressed(id: String) -> void:
	_play_click_sfx()
	match id:
		"play", "continue", "new_game":
			_go_to_intro()
		"settings", "options":
			_open_settings()
		"credits":
			_open_credits_or_noop()
		"back":
			pass
		"quit", "exit":
			_quit_to_tesana()
		_:
			push_warning("Main menu: unknown button id '" + id + "'")


func _go_to_intro() -> void:
	if ResourceLoader.exists(INTRO_SCENE):
		get_tree().change_scene_to_file(INTRO_SCENE)
	else:
		_go_to_play_direct()


func _go_to_play_direct() -> void:
	var loader := get_node_or_null("/root/LoadingScreen")
	if loader and loader.has_method("preload_and_change_scene"):
		loader.preload_and_change_scene(PLAY_TARGET_SCENE)
	else:
		get_tree().change_scene_to_file(PLAY_TARGET_SCENE)


func _open_settings() -> void:
	var path := "res://scenes/ui/settings.tscn"
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)


func _open_credits_or_noop() -> void:
	for p in ["res://scenes/ui/credits.tscn", "res://scenes/credits.tscn"]:
		if ResourceLoader.exists(p):
			get_tree().change_scene_to_file(p)
			return


func _quit_to_tesana() -> void:
	if OS.has_feature("web"):
		var js := 'try { window.top.location.href = "' + TESANA_QUIT_URL + '"; }' \
			+ ' catch (e) { window.location.href = "' + TESANA_QUIT_URL + '"; }'
		JavaScriptBridge.eval(js)
	else:
		get_tree().quit()


func _play_click_sfx() -> void:
	if _click_sfx_stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = _click_sfx_stream
	p.volume_db = -4.0
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
