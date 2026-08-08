extends Control
# 게임 시작 전 시네마틱 인트로 시퀀스.
# 아무 키/클릭으로 즉시 건너뛸 수 있음.

const GAME_SCENE := "res://scenes/game_world.tscn"
const EXTERIOR := "res://assets/textures/backgrounds/exterior.png"
const AMBIENT := "res://assets/audio/ambient/ambient_abandoned_arctic_hotel_polar_night_hotel.mp3"

var _done := false
var _loading := false
var _ext_rect: TextureRect
var _cap1: Label
var _cap2: Label
var _title_lbl: Label
var _day_lbl: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_nodes()
	_run_sequence()

func _build_nodes() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 배경 외관 이미지 (밤 분위기)
	_ext_rect = TextureRect.new()
	if ResourceLoader.exists(EXTERIOR):
		_ext_rect.texture = load(EXTERIOR)
	_ext_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ext_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_ext_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ext_rect.modulate = Color(1, 1, 1, 0)
	add_child(_ext_rect)
	_ext_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 야간 색조 오버레이 (짙은 남색)
	var night := ColorRect.new()
	night.color = Color(0.04, 0.06, 0.20, 0.62)
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(night)
	night.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 비네트 효과
	if ResourceLoader.exists("res://assets/textures/fx/vignette.png"):
		var vig := TextureRect.new()
		vig.texture = load("res://assets/textures/fx/vignette.png")
		vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		vig.stretch_mode = TextureRect.STRETCH_SCALE
		vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(vig)
		vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_cap1 = _make_caption("노르웨이, 북극권\n극야의 계절", 30)
	_cap2 = _make_caption("낡은 호텔, 어두운 복도\n그리고... 이상한 것들", 28)
	_title_lbl = _make_caption("POLARIS HOTEL", 62)
	_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.97, 0.90))
	_day_lbl = _make_caption("첫째 날", 30)
	_day_lbl.add_theme_color_override("font_color", Color(0.85, 0.70, 0.42))

	for lbl in [_cap1, _cap2]:
		add_child(lbl)
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# 타이틀은 중심보다 살짝 위, 날짜는 아래
	add_child(_title_lbl)
	_title_lbl.anchor_top = 0.0; _title_lbl.anchor_bottom = 1.0
	_title_lbl.anchor_left = 0.0; _title_lbl.anchor_right = 1.0
	_title_lbl.offset_bottom = -140
	_title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	add_child(_day_lbl)
	_day_lbl.anchor_top = 0.0; _day_lbl.anchor_bottom = 1.0
	_day_lbl.anchor_left = 0.0; _day_lbl.anchor_right = 1.0
	_day_lbl.offset_top = 140
	_day_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# 건너뛰기 안내
	var hint := Label.new()
	hint.text = "아무 키나 눌러 건너뛰기"
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.28))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_left = -220; hint.offset_right = 220
	hint.offset_top = -50;   hint.offset_bottom = -16

func _make_caption(text: String, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(0.94, 0.91, 0.85))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 3)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.modulate.a = 0.0
	return lbl

func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	var pressed := (event is InputEventKey and event.pressed and not event.echo) or \
				   (event is InputEventMouseButton and event.pressed)
	if pressed:
		_done = true
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.35)
		tw.tween_callback(_load_game)

func _run_sequence() -> void:
	# 환경음 시작 (서서히 볼륨 올리기)
	AudioManager.play_ambient(AMBIENT, -24.0)
	create_tween().tween_method(
		func(v: float): AudioManager.set_ambient_volume(v), -24.0, -8.0, 4.0)

	await _wait(0.8)

	# 외관 이미지 페이드인 (어두운 밤 분위기)
	await _fade_alpha(_ext_rect, 0.0, 0.88, 2.4)
	await _wait(0.5)
	if _done: return

	# 자막 1
	await _fade_alpha(_cap1, 0.0, 1.0, 0.9)
	await _wait(2.4)
	await _fade_alpha(_cap1, 1.0, 0.0, 0.8)
	await _wait(0.3)
	if _done: return

	# 자막 2
	await _fade_alpha(_cap2, 0.0, 1.0, 0.9)
	await _wait(2.4)
	await _fade_alpha(_cap2, 1.0, 0.0, 0.8)
	if _done: return

	# 외관 페이드아웃 → 암전
	await _fade_alpha(_ext_rect, 0.88, 0.0, 2.2)
	await _wait(0.5)
	if _done: return

	# 타이틀 등장
	await _fade_alpha(_title_lbl, 0.0, 1.0, 1.3)
	await _wait(0.5)
	await _fade_alpha(_day_lbl, 0.0, 1.0, 1.0)
	await _wait(2.6)
	if _done: return

	_done = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.1)
	await tw.finished
	_load_game()

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _fade_alpha(node: CanvasItem, from: float, to: float, dur: float) -> void:
	node.modulate.a = from
	var tw := create_tween()
	tw.tween_property(node, "modulate:a", to, dur).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

func _load_game() -> void:
	if _loading:
		return
	_loading = true
	var loader := get_node_or_null("/root/LoadingScreen")
	if loader and loader.has_method("preload_and_change_scene"):
		loader.preload_and_change_scene(GAME_SCENE)
	else:
		get_tree().change_scene_to_file(GAME_SCENE)
