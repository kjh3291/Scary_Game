class_name RulesData
extends RefCounted
# The curated 7-day schedule: which rules appear each morning, which traps
# the hotel springs, how many anomalies hide in the halls.
# Fairness contract: every trap day also shows the rule that counters it.

static func day_spec(day: int) -> Dictionary:
	match day:
		1:
			return {"rules": ["r1", "r3", "r5", "r6"], "traps": [], "count": 2}
		2:
			return {"rules": ["r1", "r2", "r5", "r6"], "traps": ["window"], "count": 3}
		3:
			return {"rules": ["r1", "r3", "r4", "r6"], "traps": ["whistle", "name_call"], "count": 3}
		4:
			return {"rules": ["r1", "r7", "r2"], "traps": [], "count": 3, "messy": true}
		5:
			return {"rules": ["r9"], "traps": [], "count": 4, "wet": true}
		6:
			return {"rules": ["r1", "r5", "r8", "r2"], "traps": ["blue_sconce", "ear_cover", "window"], "count": 5}
		7:
			return {"rules": ["r1", "r3", "r4", "r6"], "traps": ["knock307", "whistle"], "count": 6}
		_:
			return {"rules": ["r1"], "traps": [], "count": 2}
