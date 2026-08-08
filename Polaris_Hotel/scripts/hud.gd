class_name Hud
extends Control
# Always-on strip: lanterns (bottom-left), day + anomaly status above them,
# and the key hint along the bottom edge. Rules, map and journal live in
# their own toggle overlays (E / TAB / J) handled by game_world.

const LANTERN_ICON := "res://assets/ui/icon_lantern.png"

var _lantern_icons: Array = []
var _day_label: Label
var _status_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# --- lanterns, bottom-left ---
	var lantern_box := HBoxContainer.new()
	lantern_box.add_theme_constant_override("separation", 14)
	add_child(lantern_box)
	lantern_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	lantern_box.position = Vector2(28, -110)
	var tex: Texture2D = load(LANTERN_ICON)
	for i in 3:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(92, 92)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lantern_box.add_child(tr)
		_lantern_icons.append(tr)
	var lant_label := Label.new()
	lant_label.text = TextDB.HUD_LANTERN
	lant_label.add_theme_font_size_override("font_size", 22)
	lant_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	lantern_box.add_child(lant_label)

	# --- day + status, above the lanterns ---
	_day_label = Label.new()
	_day_label.add_theme_font_size_override("font_size", 24)
	_day_label.add_theme_color_override("font_color", Color(0.8, 0.76, 0.62))
	add_child(_day_label)
	_day_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_day_label.position = Vector2(28, -176)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 22)
	_status_label.add_theme_color_override("font_color", Color(0.65, 0.68, 0.6))
	add_child(_status_label)
	_status_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_status_label.position = Vector2(28, -142)

	# --- key hint, bottom edge, centered ---
	var hint := Label.new()
	hint.text = TextDB.HINT_KEYS
	hint.add_theme_font_size_override("font_size", 19)
	hint.add_theme_color_override("font_color", Color(0.62, 0.6, 0.52, 0.8))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_left = -400
	hint.offset_right = 400
	hint.offset_top = -44
	hint.offset_bottom = -12

func refresh() -> void:
	# lanterns — amber glow when lit, cold dark when extinguished
	for i in _lantern_icons.size():
		var lit: bool = i < GameState.lanterns
		_lantern_icons[i].modulate = Color(1.15, 0.88, 0.48, 1.0) if lit else Color(0.18, 0.19, 0.25, 0.65)
	# day + status
	var day_name: String = String(TextDB.DAY_NAMES.get(GameState.day, ""))
	_day_label.text = TextDB.HUD_DAY % [day_name, GameState.day]
	var left: int = GameState.anomalies_left()
	if left > 0:
		_status_label.text = TextDB.HUD_ANOMALY_LEFT % left
		_status_label.add_theme_color_override("font_color", Color(0.85, 0.6, 0.35))
	else:
		_status_label.text = TextDB.HUD_ALL_CLEAR
		_status_label.add_theme_color_override("font_color", Color(0.55, 0.8, 0.55))
