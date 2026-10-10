class_name StatRules
extends RefCounted

const BASE = {"hp": 100.0, "mobility": 180.0, "power": 100.0, "resistance": 0.0, "control": 0.0}
const LIMITS = {"hp": Vector2(70,160), "mobility": Vector2(130,230),
	"power": Vector2(85,120), "resistance": Vector2(0,25), "control": Vector2(0,25)}
const MOD_LIMITS = {"hp": 20.0, "mobility": 15.0, "power": 8.0, "resistance": 5.0, "control": 5.0}

static func finite_number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

static func limit(key: String, value: Variant) -> float:
	var number: float = float(value) if finite_number(value) else BASE[key]
	return clampf(number, LIMITS[key].x, LIMITS[key].y)

static func valid(values: Dictionary, modifiers: bool = false) -> bool:
	if not modifiers and values.size() != BASE.size():
		return false
	for key in values:
		if not BASE.has(key) or not finite_number(values[key]):
			return false
		var value := float(values[key])
		if modifiers:
			if absf(value) > MOD_LIMITS[key]:
				return false
		elif value < LIMITS[key].x or value > LIMITS[key].y:
			return false
	return true

static func calculate(base: Dictionary, modifiers: Array[Dictionary]) -> Dictionary:
	var result := {}
	for key in BASE:
		var value: float = float(base[key]) if finite_number(base.get(key)) else BASE[key]
		# Bound each input before addition, including malformed external values.
		value = clampf(value, LIMITS[key].x, LIMITS[key].y)
		for modifier in modifiers:
			if finite_number(modifier.get(key)):
				value += clampf(float(modifier[key]), -MOD_LIMITS[key], MOD_LIMITS[key])
		result[key] = clampf(value, LIMITS[key].x, LIMITS[key].y)
	result.hp = roundi(result.hp)
	return result

static func damage(raw: int, power: float, resistance: float) -> int:
	if raw <= 0:
		return 0
	var attack := limit("power", power)
	var defense := limit("resistance", resistance)
	return maxi(1, roundi(raw * attack / 100.0 * (1.0 - defense / 100.0)))

static func wind_multiplier(control: float) -> float:
	return 1.0 - limit("control", control) / 100.0
