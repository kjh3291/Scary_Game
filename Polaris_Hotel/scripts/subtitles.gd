class_name Subtitles
extends Control
# Bottom narration box. Queues lines; each shows ~3.4s; click skips ahead.
# warn() shows the red rule-violation variant.

const SHOW_TIME := 3.6

var _panel: PanelContainer
var _label: Label
var _queue: Array = []
var _timer: float = 0.0
var _showing: bool = false

var _style_normal: StyleBoxFlat
var _style_warn: StyleBoxFlat

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_style_normal = StyleBoxFlat.new()
	_style_normal.bg_color = Color(0.02, 0.03, 0.07, 0.82)
	_style_normal.border_color = Color(0.55, 0.45, 0.25, 0.5)
	_style_normal.set_border_width_all(1)
	_style_normal.set_corner_radius_all(4)
	_style_normal.content_margin_left = 28
	_style_normal.content_margin_right = 28
	_style_normal.content_margin_top = 14
	_style_normal.content_margin_bottom = 14

	_style_warn = StyleBoxFlat.new()
	_style_warn.bg_color = Color(0.16, 0.02, 0.03, 0.9)
	_style_warn.border_color = Color(0.85, 0.2, 0.15, 0.85)
	_style_warn.set_border_width_all(2)
	_style_warn.set_corner_radius_all(4)
	_style_warn.content_margin_left = 28
	_style_warn.content_margin_right = 28
	_style_warn.content_margin_top = 14
	_style_warn.content_margin_bottom = 14

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _style_normal)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.visible = false
	add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.offset_left = -700
	_panel.offset_right = 700
	_panel.offset_top = -150
	_panel.offset_bottom = -30
	_panel.gui_input.connect(_on_panel_input)

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78))
	_panel.add_child(_label)

func say(text: String) -> void:
	_queue.append({"text": text, "warn": false})
	if not _showing:
		_next()

func warn(text: String) -> void:
	_queue.append({"text": text, "warn": true})
	if not _showing:
		_next()

func clear() -> void:
	_queue.clear()
	_showing = false
	_panel.visible = false

func busy() -> bool:
	return _showing or not _queue.is_empty()

func _next() -> void:
	if _queue.is_empty():
		_showing = false
		_panel.visible = false
		return
	_showing = true
	var item: Dictionary = _queue.pop_front()
	_label.text = String(item["text"])
	if bool(item["warn"]):
		_panel.add_theme_stylebox_override("panel", _style_warn)
		_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
	else:
		_panel.add_theme_stylebox_override("panel", _style_normal)
		_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78))
	_panel.visible = true
	_timer = SHOW_TIME

func _process(delta: float) -> void:
	if not _showing:
		return
	_timer -= delta
	if _timer <= 0.0:
		_next()

func _on_panel_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_next()
		accept_event()
