extends Node
# GameState — day / lanterns / daily anomaly plan / endings. State + signals only.

signal lanterns_changed(lanterns: int)
signal day_changed(day: int)

const MAX_DAY := 7
const MAX_LANTERNS := 3

var day: int = 1
var lanterns: int = MAX_LANTERNS
var failures: int = 0           # lantern losses (slept with anomalies left)
var violations: int = 0         # rule breaks (each resets the day to 1)
var current_room: String = "room_301"
var ending: String = ""         # "", "good", "bad", "under_bed"

var day_plan: Dictionary = {}   # {rules, traps, wet, messy, anomalies}
var messy_fixed: bool = false
var note_read: bool = false

# Journal: one entry per photographed anomaly
# {type, room, day} — persists across violations, cleared on new_game.
var discovered_log: Array = []

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func rng() -> RandomNumberGenerator:
	return _rng

func new_game() -> void:
	day = 1
	failures = 0
	violations = 0
	current_room = "room_301"
	ending = ""
	discovered_log = []
	set_lanterns(MAX_LANTERNS)
	build_day_plan()

func set_lanterns(v: int) -> void:
	lanterns = clampi(v, 0, MAX_LANTERNS)
	lanterns_changed.emit(lanterns)

func fear_stage() -> int:
	return MAX_LANTERNS - lanterns

func rules_for_today() -> Array:
	var out: Array = []
	for r in day_plan.get("rules", []):
		out.append(r)
	if lanterns == 1 and not out.has("r10"):
		out.append("r10")
	return out

func has_trap(id: String) -> bool:
	return day_plan.get("traps", []).has(id)

func wet_day() -> bool:
	return bool(day_plan.get("wet", false))

func messy_day() -> bool:
	return bool(day_plan.get("messy", false)) and not messy_fixed

func anomalies() -> Array:
	return day_plan.get("anomalies", [])

func anomalies_left() -> int:
	var n: int = 0
	for a in anomalies():
		if not bool(a.get("fixed", false)):
			n += 1
	return n

func all_fixed() -> bool:
	return anomalies_left() == 0

func fix_anomaly(uid: String) -> Dictionary:
	for a in anomalies():
		if String(a.get("uid", "")) == uid and not bool(a.get("fixed", false)):
			a["fixed"] = true
			return a
	return {}

func build_day_plan() -> void:
	messy_fixed = false
	note_read = false
	var spec: Dictionary = RulesData.day_spec(day)
	day_plan = {
		"rules": spec.get("rules", []),
		"traps": spec.get("traps", []),
		"wet": bool(spec.get("wet", false)),
		"messy": bool(spec.get("messy", false)),
		"anomalies": AnomalyData.roll_anomalies(int(spec.get("count", 2)), day, bool(spec.get("messy", false)), _rng),
	}
	day_changed.emit(day)

# Sleeping. Returns: "next_day" | "repeat_day" | "good_ending" | "bad_ending"
func resolve_sleep() -> String:
	if all_fixed():
		if day >= MAX_DAY:
			ending = "good"
			return "good_ending"
		day += 1
		build_day_plan()
		return "next_day"
	failures += 1
	set_lanterns(lanterns - 1)
	if lanterns <= 0:
		ending = "bad"
		return "bad_ending"
	build_day_plan()  # same day number, fresh anomalies
	return "repeat_day"

func apply_violation() -> void:
	violations += 1
	day = 1
	build_day_plan()
