class_name ExplosionResolver
extends RefCounted

static func splash(profile: WeaponProfile, distance: float) -> int:
	if distance >= profile.explosion_radius:
		return 0
	return maxi(profile.splash_min, roundi(profile.splash_max * (1.0 - distance / profile.explosion_radius)))

static func apply(profile: WeaponProfile, collider: Object, point: Vector2,
		players: Array[CombatPlayer], map: Node2D, power: float = 100.0) -> void:
	map.queue_explosion(point, profile.crater_radius)
	for player in players:
		var damage := profile.direct_damage if player == collider else splash(profile, player.global_position.distance_to(point))
		player.take_damage(StatRules.damage(damage, power, float(player.stats.resistance)))
