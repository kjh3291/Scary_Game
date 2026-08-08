class_name RoomData
extends RefCounted
# Room graph + per-room identity: background, walkable floor band, sconce
# light positions, hotspot rectangles, anomaly anchor rects.
# All rects are [x, y, w, h] in 1920x1080 space, measured against each room's
# own background art. Every room is walkable; the player moves on the floor
# band (x range + depth between y_far and y_near).

const GUEST_ROOMS := ["room_302", "room_303", "room_304", "room_305", "room_306"]
const ALL_ROOMS := ["room_301", "room_302", "room_303", "room_304", "room_305", "room_306", "corridor", "elevator_hall", "lobby"]

# Corridor door x-centers, left to right: 301 .. 306
const CORRIDOR_DOORS := {
	"room_301": 520, "room_302": 835, "room_303": 1120,
	"room_304": 1355, "room_305": 1595, "room_306": 1815,
}

# --- Per-room table -----------------------------------------------------------
# walk: [x_min, x_max, y_far, y_near] — feet stay inside this band.
# entry: where the player appears walking in through the door.
# lights: [x, y, energy, scale] warm sconce pools (per-room fixtures).
const ROOMS := {
	"room_301": {
		"bg": "res://assets/textures/backgrounds/room_301.png",
		"walk": [140, 1820, 800, 930],
		"entry": Vector2(300, 870),
		"lights": [
			[435, 640, 1.0, 2.6],
			[1400, 520, 0.8, 2.2],
		],
	},
	"room_302": {
		"bg": "res://assets/textures/backgrounds/room_302.png",
		"walk": [120, 1850, 850, 990],
		"entry": Vector2(270, 920),
		"lights": [
			[490, 540, 0.9, 2.2],
			[940, 540, 0.9, 2.2],
		],
	},
	"room_303": {
		"bg": "res://assets/textures/backgrounds/room_303.png",
		"walk": [140, 1860, 880, 1010],
		"entry": Vector2(400, 940),
		"lights": [
			[530, 520, 0.85, 2.1],
			[820, 440, 0.9, 2.2],
		],
	},
	"room_304": {
		"bg": "res://assets/textures/backgrounds/room_304.png",
		"walk": [130, 1850, 870, 1010],
		"entry": Vector2(360, 940),
		"lights": [
			[575, 570, 0.9, 2.2],
			[1315, 500, 0.85, 2.1],
		],
	},
	"room_305": {
		"bg": "res://assets/textures/backgrounds/room_305.png",
		"walk": [120, 1860, 880, 1010],
		"entry": Vector2(250, 940),
		"lights": [
			[830, 480, 0.75, 1.9],  # the dying room: one weak sconce only
		],
	},
	"room_306": {
		"bg": "res://assets/textures/backgrounds/room_306.png",
		"walk": [80, 1880, 860, 1000],
		"entry": Vector2(200, 930),
		"lights": [
			[550, 510, 0.85, 2.1],
			[960, 510, 0.85, 2.1],
			[1705, 550, 0.8, 2.0],
		],
	},
	"corridor": {
		"bg": "res://assets/textures/backgrounds/corridor.png",
		"walk": [150, 1860, 805, 878],
		"entry": Vector2(300, 845),
		"lights": [
			[390, 520, 0.85, 2.1],
			[670, 520, 0.85, 2.1],
			[980, 520, 0.85, 2.1],
			[1240, 520, 0.85, 2.1],
			[1480, 520, 0.85, 2.1],
			[1715, 520, 0.85, 2.1],
		],
	},
	"elevator_hall": {
		"bg": "res://assets/textures/backgrounds/elevator_hall.png",
		"walk": [130, 1840, 830, 900],
		"entry": Vector2(430, 865),
		"lights": [
			[500, 420, 0.75, 2.0],
			[960, 420, 0.8, 2.4],
			[1450, 420, 0.7, 2.0],
		],
	},
	"lobby": {
		"bg": "res://assets/textures/backgrounds/lobby.png",
		"walk": [170, 1820, 865, 950],
		"entry": Vector2(1240, 905),
		"lights": [
			[600, 480, 0.7, 2.0],
			[1180, 350, 0.85, 2.6],
			[1650, 500, 0.7, 2.2],
		],
	},
}

const BG_EXTERIOR := "res://assets/textures/backgrounds/exterior.png"

static func bg_for(room_id: String) -> String:
	return String(ROOMS.get(room_id, ROOMS["room_302"]).get("bg", ""))

static func is_guest_room(room_id: String) -> bool:
	return GUEST_ROOMS.has(room_id)

static func rect(a: Array) -> Rect2:
	return Rect2(a[0], a[1], a[2], a[3])

# Walkable band: position = (x_min, y_far), size = (x_max - x_min, y_near - y_far)
static func walk_band(room_id: String) -> Rect2:
	var w: Array = ROOMS.get(room_id, ROOMS["room_301"]).get("walk", [150, 1850, 820, 940])
	return Rect2(float(w[0]), float(w[2]), float(w[1]) - float(w[0]), float(w[3]) - float(w[2]))

static func entry_for(room_id: String) -> Vector2:
	return ROOMS.get(room_id, ROOMS["room_301"]).get("entry", Vector2(300, 880))

static func lights_for(room_id: String) -> Array:
	return ROOMS.get(room_id, {}).get("lights", [])

# --- Hotspots -------------------------------------------------------------
# kind: flavor | bed | note | window | under_bed | exit | door | elevator |
#       sconce | stairs | anomaly (spawned separately)
# All are activated by proximity + [F]; "reach" overrides the default range.
static func hotspots_for(room_id: String) -> Array:
	match room_id:
		"room_301":
			return [
				{"id": "bed", "kind": "bed", "rect": [500, 590, 620, 330]},
				{"id": "note", "kind": "note", "rect": [340, 600, 200, 160]},
				{"id": "window", "kind": "window", "rect": [1050, 240, 440, 430], "reach": 230},
				{"id": "painting", "kind": "flavor", "rect": [465, 340, 170, 180], "line": "paint_301", "wall": true, "reach": 240},
				{"id": "mirror", "kind": "flavor", "rect": [1550, 300, 290, 370], "line": "mirror", "wall": true, "reach": 240},
				{"id": "under_bed", "kind": "under_bed", "rect": [500, 860, 520, 110]},
				{"id": "door", "kind": "exit", "rect": [80, 240, 240, 650], "to": "corridor", "reach": 200},
			]
		"room_302":
			return [
				{"id": "door", "kind": "exit", "rect": [110, 280, 260, 600], "to": "corridor", "reach": 200},
				{"id": "bed", "kind": "flavor", "rect": [560, 570, 570, 300], "line": "bed_guest"},
				{"id": "painting", "kind": "flavor", "rect": [600, 290, 250, 230], "line": "paint_302", "wall": true, "reach": 260},
				{"id": "wardrobe", "kind": "flavor", "rect": [1050, 320, 310, 500], "line": "wardrobe_302"},
				{"id": "window", "kind": "window", "rect": [1490, 160, 310, 540], "reach": 260},
				{"id": "table", "kind": "flavor", "rect": [1710, 640, 210, 250], "line": "table_302"},
				{"id": "radiator", "kind": "flavor", "rect": [0, 640, 90, 200], "line": "radiator_302", "reach": 220},
			]
		"room_303":
			return [
				{"id": "door", "kind": "exit", "rect": [230, 300, 270, 590], "to": "corridor", "reach": 200},
				{"id": "vanity", "kind": "flavor", "rect": [660, 450, 340, 420], "line": "vanity_303"},
				{"id": "stool", "kind": "flavor", "rect": [800, 760, 120, 120], "line": "stool_303"},
				{"id": "painting", "kind": "flavor", "rect": [1070, 380, 170, 150], "line": "paint_303", "wall": true, "reach": 280},
				{"id": "bed", "kind": "flavor", "rect": [1060, 590, 510, 340], "line": "bed_303"},
				{"id": "window", "kind": "window", "rect": [1620, 90, 280, 620], "reach": 260},
				{"id": "armchair", "kind": "flavor", "rect": [0, 750, 210, 220], "line": "chair", "reach": 220},
			]
		"room_304":
			return [
				{"id": "door", "kind": "exit", "rect": [200, 340, 240, 500], "to": "corridor", "reach": 200},
				{"id": "desk", "kind": "flavor", "rect": [480, 640, 390, 240], "line": "desk_304"},
				{"id": "shelf", "kind": "flavor", "rect": [970, 320, 290, 530], "line": "shelf_304"},
				{"id": "coat", "kind": "flavor", "rect": [30, 560, 90, 290], "line": "coat_304", "reach": 220},
				{"id": "bed", "kind": "flavor", "rect": [1270, 620, 490, 300], "line": "bed_guest"},
				{"id": "window", "kind": "window", "rect": [1610, 190, 290, 510], "reach": 260},
				{"id": "trunk", "kind": "flavor", "rect": [1580, 850, 200, 100], "line": "trunk_304"},
			]
		"room_305":
			return [
				{"id": "door", "kind": "exit", "rect": [110, 380, 220, 500], "to": "corridor", "reach": 200},
				{"id": "bed", "kind": "flavor", "rect": [580, 560, 480, 330], "line": "bed_305"},
				{"id": "painting", "kind": "flavor", "rect": [1000, 420, 170, 150], "line": "paint_305", "wall": true, "reach": 280},
				{"id": "dresser", "kind": "flavor", "rect": [1180, 500, 290, 330], "line": "dresser_305"},
				{"id": "window", "kind": "window", "rect": [1560, 250, 340, 510], "reach": 260},
				{"id": "debris", "kind": "flavor", "rect": [1250, 850, 380, 140], "line": "debris_305"},
			]
		"room_306":
			return [
				{"id": "door", "kind": "exit", "rect": [30, 390, 140, 470], "to": "corridor", "reach": 220},
				{"id": "fireplace", "kind": "flavor", "rect": [560, 560, 390, 270], "line": "fireplace_306"},
				{"id": "armchair", "kind": "flavor", "rect": [380, 640, 210, 260], "line": "armchair_306"},
				{"id": "cameo", "kind": "flavor", "rect": [1060, 390, 100, 130], "line": "cameo_306", "wall": true, "reach": 280},
				{"id": "window", "kind": "window", "rect": [1290, 270, 250, 460], "reach": 260},
				{"id": "mirror", "kind": "flavor", "rect": [1770, 270, 150, 350], "line": "mirror_306", "wall": true, "reach": 260},
				{"id": "bed", "kind": "flavor", "rect": [1420, 620, 480, 290], "line": "bed_guest"},
			]
		"corridor":
			var out: Array = [
				{"id": "window", "kind": "window", "rect": [40, 150, 230, 560], "reach": 240},
				{"id": "exit_east", "kind": "exit", "rect": [1800, 300, 120, 540], "to": "elevator_hall", "reach": 170},
			]
			for rid in CORRIDOR_DOORS.keys():
				var cx: int = CORRIDOR_DOORS[rid]
				out.append({"id": "door_" + rid, "kind": "door", "rect": [cx - 70, 410, 140, 400], "to": rid, "reach": 170})
			var sx: Array = [390, 670, 980, 1240, 1480, 1715]
			for i in sx.size():
				out.append({"id": "sconce_%d" % i, "kind": "sconce", "rect": [sx[i] - 45, 460, 90, 120], "wall": true, "reach": 240})
			return out
		"elevator_hall":
			return [
				{"id": "elevator", "kind": "elevator", "rect": [990, 270, 400, 580], "reach": 200},
				{"id": "call_button", "kind": "flavor", "rect": [1420, 520, 80, 120], "line": "call_button", "wall": true, "reach": 200},
				{"id": "painting_l", "kind": "flavor", "rect": [630, 300, 230, 250], "line": "paint_hall", "wall": true, "reach": 260},
				{"id": "painting_r", "kind": "flavor", "rect": [1550, 300, 230, 250], "line": "paint_hall", "wall": true, "reach": 260},
				{"id": "flowers", "kind": "flavor", "rect": [610, 530, 270, 320], "line": "flowers"},
				{"id": "exit_west", "kind": "exit", "rect": [0, 280, 300, 570], "to": "corridor", "reach": 220},
			]
		"lobby":
			return [
				{"id": "window", "kind": "window", "rect": [0, 60, 700, 640], "reach": 260},
				{"id": "desk", "kind": "flavor", "rect": [1440, 600, 480, 270], "line": "desk"},
				{"id": "stairs", "kind": "exit", "rect": [1100, 260, 280, 560], "to": "elevator_hall", "reach": 220, "prompt": "stairs"},
				{"id": "painting", "kind": "flavor", "rect": [950, 220, 170, 150], "line": "paint_hall", "wall": true, "reach": 260},
			]
		_:
			return []

# --- Anomaly anchor rects ---------------------------------------------------
static func anchors_for(room_id: String) -> Dictionary:
	match room_id:
		"room_301":
			return {
				"wall_a": [650, 180, 300, 280], "wall_b": [1500, 180, 280, 240],
				"painting": [465, 340, 170, 180], "window": [1050, 240, 440, 430],
				"floor": [560, 700, 400, 180],
			}
		"room_302":
			return {
				"wall_a": [900, 180, 300, 240], "wall_b": [1150, 180, 300, 260],
				"wall_c": [380, 180, 200, 240],
				"painting": [600, 290, 250, 230], "window": [1490, 160, 310, 530],
				"floor": [1250, 850, 350, 150],
			}
		"room_303":
			return {
				"wall_a": [1260, 170, 300, 250], "wall_b": [30, 140, 300, 270],
				"painting": [730, 460, 200, 270], "window": [1620, 90, 280, 620],
				"floor": [300, 880, 380, 150],
			}
		"room_304":
			return {
				"wall_a": [1330, 180, 300, 270], "wall_b": [40, 150, 250, 240],
				"painting": [630, 350, 160, 180], "window": [1610, 190, 290, 510],
				"floor": [900, 880, 350, 150],
			}
		"room_305":
			return {
				"wall_a": [1200, 180, 320, 260], "wall_b": [60, 150, 250, 230],
				"painting": [1000, 420, 170, 150], "painting_b": [530, 370, 190, 160],
				"window": [1560, 250, 340, 510],
				"floor": [1100, 880, 380, 150],
			}
		"room_306":
			return {
				"wall_a": [990, 170, 280, 240], "wall_b": [40, 150, 260, 230],
				"painting": [660, 230, 180, 250], "painting_b": [1770, 270, 150, 350],
				"window": [1290, 270, 250, 460],
				"floor": [1000, 870, 380, 150],
			}
		"corridor":
			return {
				"wall_a": [600, 250, 160, 170], "wall_b": [1180, 250, 160, 170],
				"wall_c": [1400, 250, 160, 170], "floor": [900, 790, 300, 140],
				"door_301": [450, 410, 140, 390], "door_302": [765, 410, 140, 390],
				"door_303": [1050, 410, 140, 390], "door_304": [1285, 410, 140, 390],
				"door_305": [1525, 410, 140, 390], "door_306": [1745, 410, 140, 390],
				"seventh_door": [950, 420, 180, 370],
			}
		"elevator_hall":
			return {
				"wall_a": [500, 200, 300, 180], "floor": [1450, 700, 320, 170],
				"painting": [630, 300, 230, 250], "painting_b": [1550, 300, 230, 250],
				"elevator": [990, 270, 400, 570],
			}
		"lobby":
			return {
				"wall_a": [950, 220, 170, 140], "floor": [700, 790, 350, 170],
				"painting": [950, 220, 170, 140], "window": [60, 100, 600, 560],
			}
		_:
			return {}
