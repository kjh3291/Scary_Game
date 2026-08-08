extends Control

const CONFIG_PATH := "user://settings.cfg"
const MENU_SCENE := "res://scenes/main.tscn"

var _slider: HSlider
var _pct_label: Label
var _cfg := ConfigFile.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cfg.load(CONFIG_PATH)
	_build_ui()
	var saved: float = _cfg.get_value("audio", "master_volume", 0.8)
	_slider.value = saved
	_apply_volume(saved)

func _build_ui() -> void:
	# Background — same dark tone as main menu
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.10, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Faint title poster for atmosphere
	if ResourceLoader.exists("res://assets/ui/title_poster.webp"):
		var poster := TextureRect.new()
		poster.texture = load("res://assets/ui/title_poster.webp")
		poster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		poster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		poster.modulate = Color(1, 1, 1, 0.07)
		poster.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(poster)
		poster.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 32)
	center.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "설정"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.92, 0.86, 0.68))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var divider := ColorRect.new()
	divider.color = Color(0.45, 0.38, 0.25, 0.5)
	divider.custom_minimum_size = Vector2(380, 1)
	vbox.add_child(divider)

	# Volume section
	var vol_box := VBoxContainer.new()
	vol_box.add_theme_constant_override("separation", 12)
	vbox.add_child(vol_box)

	var vol_row := HBoxContainer.new()
	vol_row.add_theme_constant_override("separation", 14)
	vol_box.add_child(vol_row)

	var lbl := Label.new()
	lbl.text = "전체 음량"
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.74, 0.70, 0.58))
	lbl.custom_minimum_size = Vector2(130, 0)
	vol_row.add_child(lbl)

	_pct_label = Label.new()
	_pct_label.add_theme_font_size_override("font_size", 22)
	_pct_label.add_theme_color_override("font_color", Color(0.88, 0.82, 0.62))
	_pct_label.custom_minimum_size = Vector2(56, 0)
	_pct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vol_row.add_child(_pct_label)

	_slider = HSlider.new()
	_slider.min_value = 0.0
	_slider.max_value = 1.0
	_slider.step = 0.02
	_slider.value = 0.8
	_slider.custom_minimum_size = Vector2(380, 40)
	_slider.focus_mode = Control.FOCUS_NONE
	_slider.value_changed.connect(_on_volume_changed)
	vol_box.add_child(_slider)

	_pct_label.text = "80%"

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 14)
	vbox.add_child(spacer)

	# Back button
	var back := Button.new()
	back.text = "  돌아가기"
	back.custom_minimum_size = Vector2(300, 76)
	back.add_theme_font_size_override("font_size", 24)
	back.add_theme_color_override("font_color", Color(0.85, 0.78, 0.60))
	back.focus_mode = Control.FOCUS_NONE
	back.add_theme_stylebox_override("normal", _make_sb(Color(0.14, 0.12, 0.09, 0.92), Color(0.42, 0.36, 0.24, 0.85)))
	back.add_theme_stylebox_override("hover",  _make_sb(Color(0.22, 0.19, 0.14, 1.0),  Color(0.62, 0.52, 0.32, 1.0)))
	back.add_theme_stylebox_override("pressed", _make_sb(Color(0.22, 0.19, 0.14, 1.0), Color(0.62, 0.52, 0.32, 1.0)))
	back.add_theme_stylebox_override("focus", _make_sb(Color(0.14, 0.12, 0.09, 0.92), Color(0.42, 0.36, 0.24, 0.85)))
	back.pressed.connect(_on_back)
	vbox.add_child(back)

func _make_sb(bg: Color, border: Color) -> StyleBoxFlat:
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

func _on_volume_changed(v: float) -> void:
	_pct_label.text = "%d%%" % int(v * 100)
	_apply_volume(v)
	_cfg.set_value("audio", "master_volume", v)
	_cfg.save(CONFIG_PATH)

func _apply_volume(v: float) -> void:
	var db := linear_to_db(v) if v > 0.001 else -80.0
	AudioServer.set_bus_volume_db(0, db)

func _on_back() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
