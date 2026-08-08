class_name Minimap
extends Control
# Custom-drawn hotel map: 6 rooms flanking the 3F corridor, EV hall, lobby.
# The current room glows warm; a room erased by the hotel is crossed out.

var current_room: String = "room_301"
var missing_room: String = ""   # stage-3: one guest room is gone

const C_LIT := Color(0.95, 0.75, 0.35, 0.9)
const C_DIM := Color(0.28, 0.32, 0.45, 0.75)
const C_LINE := Color(0.55, 0.48, 0.32, 0.55)
const C_BG := Color(0.02, 0.03, 0.07, 0.78)

func _ready() -> void:
	custom_minimum_size = Vector2(430, 210)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_current(room_id: String) -> void:
	current_room = room_id
	queue_redraw()

func set_missing(room_id: String) -> void:
	missing_room = room_id
	queue_redraw()

func _box(r: Rect2, room_id: String, label: String) -> void:
	var lit: bool = (current_room == room_id)
	draw_rect(r, C_LIT if lit else C_DIM, true)
	draw_rect(r, C_LINE, false, 2.0)
	var font: Font = get_theme_default_font()
	var fs: int = 20
	var tw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, r.position + Vector2((r.size.x - tw) * 0.5, r.size.y * 0.5 + 7), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.06, 0.07, 0.1) if lit else Color(0.8, 0.78, 0.7))
	if missing_room == room_id:
		draw_line(r.position, r.position + r.size, Color(0.8, 0.2, 0.15, 0.9), 3.0)
		draw_line(r.position + Vector2(r.size.x, 0), r.position + Vector2(0, r.size.y), Color(0.8, 0.2, 0.15, 0.9), 3.0)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, custom_minimum_size), C_BG, true)
	var labels: Dictionary = TextDB.MINIMAP
	# corridor strip
	_box(Rect2(70, 84, 270, 40), "corridor", labels["corridor"])
	# rooms 301-303 above, 304-306 below
	_box(Rect2(76, 30, 60, 34), "room_301", labels["r301"])
	_box(Rect2(146, 30, 60, 34), "room_302", labels["r302"])
	_box(Rect2(216, 30, 60, 34), "room_303", labels["r303"])
	_box(Rect2(76, 144, 60, 34), "room_304", labels["r304"])
	_box(Rect2(146, 144, 60, 34), "room_305", labels["r305"])
	_box(Rect2(216, 144, 60, 34), "room_306", labels["r306"])
	# EV hall + lobby on the right
	_box(Rect2(356, 84, 56, 40), "elevator_hall", labels["ev"])
	_box(Rect2(356, 138, 56, 40), "lobby", labels["lobby"])
	# link lines
	draw_line(Vector2(340, 104), Vector2(356, 104), C_LINE, 2.0)
	draw_line(Vector2(384, 124), Vector2(384, 138), C_LINE, 2.0)
