class_name AimAssist
extends RefCounted

# OFF: no guide. NORMAL: barrel guide (original behavior). ASSISTED: guide plus a
# short predicted arc while charging. Ranked play must force OFF (see allowed()).
enum Mode { OFF, NORMAL, ASSISTED }
const NAMES: Array[String] = ["OFF", "NORMAL", "ASSISTED"]
const PREVIEW_SECONDS: float = 0.9

static func next(mode: int) -> int:
	return (mode + 1) % NAMES.size()

static func title(mode: int) -> String:
	return NAMES[clampi(mode, 0, NAMES.size() - 1)]

static func allowed(mode: int, ranked: bool) -> int:
	return Mode.OFF if ranked else mode
