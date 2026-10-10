class_name BallisticSolver
extends RefCounted

# Single source of truth for projectile kinematics. Projectiles, aim preview and
# debug overlay all integrate with these functions, so prediction cannot drift
# from the real flight. Pure math: no nodes, no physics access unless a hit_test
# Callable(from, to, ...) -> Dictionary is supplied by the caller.

static func aim_vector(angle_degrees: float, facing: int) -> Vector2:
	var radians := deg_to_rad(angle_degrees)
	return Vector2(cos(radians) * facing, -sin(radians))

static func speed(profile: WeaponProfile, power_ratio: float) -> float:
	return lerpf(profile.min_speed, profile.max_speed, clampf(power_ratio, 0.0, 1.0))

static func launch_velocity(profile: WeaponProfile, angle_degrees: float, facing: int, power_ratio: float) -> Vector2:
	return aim_vector(angle_degrees, facing) * speed(profile, power_ratio)

# Pellet angle inside a volley, centered on the aimed angle.
static func volley_angle(base_angle: float, index: int, count: int, spread: float) -> float:
	return base_angle + (index - (count - 1) * 0.5) * spread

static func acceleration(profile: WeaponProfile, wind: int, control: float = 0.0) -> Vector2:
	return Vector2(wind * CombatConfig.WIND_ACCELERATION * profile.wind_factor * StatRules.wind_multiplier(control),
		profile.gravity)

# Constant acceleration: exact endpoints for each fixed physics tick.
static func next_position(position: Vector2, velocity: Vector2, accel: Vector2, delta: float) -> Vector2:
	return position + velocity * delta + accel * (0.5 * delta * delta)

static func next_velocity(velocity: Vector2, accel: Vector2, delta: float) -> Vector2:
	return velocity + accel * delta

# Simulates the flight. With sample_steps = 1 it matches the real projectile tick
# for tick; larger values test collisions on chords between samples (cheaper).
# Returns {"points": PackedVector2Array, "hit": Dictionary, "time": float}.
static func predict(origin: Vector2, velocity: Vector2, accel: Vector2, hit_test: Callable = Callable(),
		max_time: float = CombatConfig.SHOT_LIFETIME, sample_steps: int = 1) -> Dictionary:
	var delta := 1.0 / float(Engine.physics_ticks_per_second)
	var steps := int(max_time / delta)
	var stride := maxi(1, sample_steps)
	var points := PackedVector2Array([origin])
	var position := origin
	var chunk_start := origin
	var current := velocity
	for step in range(1, steps + 1):
		var next := next_position(position, current, accel, delta)
		current = next_velocity(current, accel, delta)
		position = next
		if step % stride == 0 or step == steps:
			if hit_test.is_valid():
				var hit: Dictionary = hit_test.call(chunk_start, position)
				if not hit.is_empty():
					points.append(hit.position)
					return {"points": points, "hit": hit, "time": step * delta}
			points.append(position)
			chunk_start = position
		if not CombatConfig.SHOT_BOUNDS.has_point(position):
			break
	return {"points": points, "hit": {}, "time": steps * delta}
