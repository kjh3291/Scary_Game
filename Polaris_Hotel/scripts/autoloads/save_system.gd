extends Node
# SaveSystem — 단일 슬롯 자동 저장.
# 저장: 수면 후 / 이상현상 해결 후 / 규칙 위반 후
# 삭제: 엔딩 도달 시

const SAVE_PATH := "user://polaris_save.json"
const VERSION := 1

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save() -> void:
	var data := {
		"version":      VERSION,
		"day":          GameState.day,
		"lanterns":     GameState.lanterns,
		"failures":     GameState.failures,
		"violations":   GameState.violations,
		"messy_fixed":  GameState.messy_fixed,
		"note_read":    GameState.note_read,
		"discovered_log": GameState.discovered_log.duplicate(true),
		"day_plan":     _serialize_plan(GameState.day_plan),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		return false
	var data: Dictionary = parsed as Dictionary
	if int(data.get("version", 0)) != VERSION:
		delete_save()
		return false
	_apply(data)
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

# 메인 메뉴 배너용 — 전체 로드 없이 day/lanterns만 미리 읽음
func peek() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return {}
	var d: Dictionary = parsed as Dictionary
	return {"day": int(d.get("day", 1)), "lanterns": int(d.get("lanterns", 3))}

func _apply(data: Dictionary) -> void:
	GameState.day          = int(data.get("day", 1))
	GameState.failures     = int(data.get("failures", 0))
	GameState.violations   = int(data.get("violations", 0))
	GameState.messy_fixed  = bool(data.get("messy_fixed", false))
	GameState.note_read    = bool(data.get("note_read", false))
	GameState.discovered_log = _to_array(data.get("discovered_log", []))
	GameState.day_plan       = _deserialize_plan(data.get("day_plan", {}))
	# set_lanterns가 lanterns_changed 신호를 발생시켜 HUD 갱신
	GameState.set_lanterns(int(data.get("lanterns", GameState.MAX_LANTERNS)))
	GameState.day_changed.emit(GameState.day)

func _serialize_plan(plan: Dictionary) -> Dictionary:
	var anomalies: Array = []
	for a in plan.get("anomalies", []):
		anomalies.append({
			"uid":    String(a.get("uid", "")),
			"type":   String(a.get("type", "")),
			"room":   String(a.get("room", "")),
			"anchor": String(a.get("anchor", "")),
			"fixed":  bool(a.get("fixed", false)),
		})
	return {
		"rules":     _to_array(plan.get("rules", [])),
		"traps":     _to_array(plan.get("traps", [])),
		"wet":       bool(plan.get("wet", false)),
		"messy":     bool(plan.get("messy", false)),
		"anomalies": anomalies,
	}

func _deserialize_plan(data: Dictionary) -> Dictionary:
	var anomalies: Array = []
	for a in _to_array(data.get("anomalies", [])):
		if a is Dictionary:
			anomalies.append({
				"uid":    String(a.get("uid", "")),
				"type":   String(a.get("type", "")),
				"room":   String(a.get("room", "")),
				"anchor": String(a.get("anchor", "")),
				"fixed":  bool(a.get("fixed", false)),
			})
	return {
		"rules":     _to_array(data.get("rules", [])),
		"traps":     _to_array(data.get("traps", [])),
		"wet":       bool(data.get("wet", false)),
		"messy":     bool(data.get("messy", false)),
		"anomalies": anomalies,
	}

func _to_array(v) -> Array:
	return v if v is Array else []
