class_name Hotspot
extends Control
# Passive interaction region. No mouse handling, no drawing — game_world
# finds the nearest hotspot within reach of the player's feet and offers
# it as the [F] action. `rect` data comes from RoomData; position/size hold it.

var hs_id: String = ""
var kind: String = "flavor"
var data: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

# Distance from a point (player feet) to this rect — 0 when inside.
# Wall-mounted items (paintings, sconces, mirrors) hang far above the walk
# band, so only horizontal distance counts: stand beneath it to use it.
func distance_to_point(p: Vector2) -> float:
	var r := Rect2(position, size)
	if bool(data.get("wall", false)):
		var dx: float = maxf(r.position.x - p.x, p.x - r.end.x)
		return maxf(dx, 0.0)
	var dx2: float = maxf(r.position.x - p.x, p.x - r.end.x)
	var dy: float = maxf(r.position.y - p.y, p.y - r.end.y)
	return Vector2(maxf(dx2, 0.0), maxf(dy, 0.0)).length()

func reach() -> float:
	return float(data.get("reach", 170.0))

func prompt_key() -> String:
	return String(data.get("prompt", kind))
