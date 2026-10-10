class_name ShotFeedback
extends RefCounted

# Explains a shot to the player: how it ended and how far it was from the target.
enum Kind { MISS, NEAR_HIT, DIRECT_HIT }

# offset is signed along the shooter's facing: negative fell short, positive went long.
static func evaluate(profile: WeaponProfile, collider: Object, point: Vector2,
		shooter: CombatPlayer, target: CombatPlayer) -> Dictionary:
	var center := target.global_position
	var kind := Kind.MISS
	if collider == target:
		kind = Kind.DIRECT_HIT
	elif point.distance_to(center) < profile.explosion_radius:
		kind = Kind.NEAR_HIT
	return {"kind": kind, "distance": point.distance_to(center),
		"offset": (point.x - center.x) * float(shooter.facing), "point": point}

# Higher is better; used to pick the best shell of a volley.
static func score(result: Dictionary) -> float:
	return float(result.kind) * 100000.0 - float(result.distance)

static func text(result: Dictionary) -> String:
	if result.is_empty():
		return "FORA DO MAPA"
	var names := ["MISS", "NEAR HIT", "DIRECT HIT"]
	if result.kind == Kind.DIRECT_HIT:
		return names[result.kind]
	return "%s  %+d px" % [names[result.kind], roundi(result.offset)]

static func color(result: Dictionary) -> Color:
	if result.is_empty():
		return Color("9fb0c0")
	return [Color("f5a36e"), Color("ffe195"), Color("7ee08a")][result.kind]
