class_name WindSystem
extends RefCounted

# Wind rules and presentation in one place. Sign = direction, magnitude = strength.
static func roll(random: MatchRandom, max_wind: int = CombatConfig.MAX_WIND) -> int:
	return random.int_range(-max_wind, max_wind)

# 0 calm, 1 weak, 2 medium, 3 strong (relative to the range maximum).
static func strength(wind: int, max_wind: int = CombatConfig.MAX_WIND) -> int:
	var ratio := absf(float(wind)) / maxf(1.0, float(max_wind))
	if wind == 0:
		return 0
	if ratio <= 0.4:
		return 1
	return 2 if ratio <= 0.8 else 3

static func arrows(wind: int, max_wind: int = CombatConfig.MAX_WIND) -> String:
	var level := strength(wind, max_wind)
	if level == 0:
		return "—"
	return ("←" if wind < 0 else "→").repeat(level)

static func label(wind: int, max_wind: int = CombatConfig.MAX_WIND) -> String:
	var names := ["CALMO", "FRACO", "MÉDIO", "FORTE"]
	var level := strength(wind, max_wind)
	if level == 0:
		return "— VENTO CALMO"
	return "%s VENTO %s (%d)" % [arrows(wind, max_wind), names[level], absi(wind)]
