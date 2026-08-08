class_name AnomalyData
extends RefCounted
# Anomaly types, eligible rooms/anchors, and the daily roll.

# type -> {rooms (eligible), anchors (anchor keys allowed in those rooms), sprite}
const TYPES := {
	"eyes": {
		"rooms": ["corridor", "room_301", "room_302", "room_303", "room_304", "room_305", "room_306", "elevator_hall"],
		"anchors": ["wall_a", "wall_b", "wall_c"],
		"sprite": "res://assets/sprites/items/anomaly_eyes.png",
	},
	"writing": {
		"rooms": ["corridor", "room_301", "room_302", "room_303", "room_304", "room_305", "room_306", "elevator_hall", "lobby"],
		"anchors": ["wall_a", "wall_b", "wall_c"],
		"sprite": "res://assets/sprites/items/anomaly_writing.png",
	},
	"stain": {
		"rooms": ["corridor", "room_301", "room_302", "room_303", "room_304", "room_305", "room_306", "elevator_hall", "lobby"],
		"anchors": ["floor", "wall_a", "wall_b"],
		"sprite": "res://assets/sprites/items/anomaly_stain.png",
	},
	"paint_eyes": {
		"rooms": ["room_301", "room_302", "room_303", "room_304", "room_305", "room_306", "elevator_hall", "lobby"],
		"anchors": ["painting", "painting_b"],
		"sprite": "res://assets/sprites/items/anomaly_eyes.png",
	},
	"figure_window": {
		"rooms": ["room_301", "room_302", "room_303", "room_304", "room_305", "room_306", "lobby"],
		"anchors": ["window"],
		"sprite": "res://assets/sprites/characters/shadow_figure_idle.png",
	},
	"door_number": {
		"rooms": ["corridor"],
		"anchors": ["door_301", "door_302", "door_303", "door_304", "door_305", "door_306"],
		"sprite": "",
	},
	"ajar": {
		"rooms": ["corridor"],
		"anchors": ["door_302", "door_303", "door_304", "door_305", "door_306"],
		"sprite": "res://assets/sprites/items/hotel_door.png",
	},
	"elevator": {
		"rooms": ["elevator_hall"],
		"anchors": ["elevator"],
		"sprite": "",
	},
}

static func roll_anomalies(count: int, day: int, messy: bool, rng: RandomNumberGenerator) -> Array:
	# Day 1 is a curated, gentle pair (tutorial).
	if day == 1:
		return [
			{"uid": "a0", "type": "stain", "room": "room_301", "anchor": "floor", "fixed": false},
			{"uid": "a1", "type": "eyes", "room": "corridor", "anchor": "wall_b", "fixed": false},
		]

	var candidates: Array = []
	for t in TYPES.keys():
		var spec: Dictionary = TYPES[t]
		for room in spec["rooms"]:
			if messy and room != "room_301":
				continue
			var room_anchors: Dictionary = RoomData.anchors_for(room)
			for anchor in spec["anchors"]:
				if room_anchors.has(anchor):
					candidates.append({"type": t, "room": room, "anchor": anchor})

	# Shuffle (Fisher-Yates with the passed rng).
	for i in range(candidates.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Dictionary = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp

	var out: Array = []
	var used_rooms: Dictionary = {}
	var n: int = mini(count, candidates.size())
	for c in candidates:
		if out.size() >= n:
			break
		# At most one anomaly per room keeps the hunt spread out,
		# unless a messy day forces everything into 301.
		if not messy:
			var rk: String = c["room"]
			if int(used_rooms.get(rk, 0)) >= 1:
				continue
			used_rooms[rk] = 1
		out.append({
			"uid": "a%d" % out.size(),
			"type": c["type"], "room": c["room"], "anchor": c["anchor"],
			"fixed": false,
		})
	return out

static func sprite_for(type: String) -> String:
	return String(TYPES.get(type, {}).get("sprite", ""))
