class_name CombatProjectile
extends Node2D

signal finished(collider: Object, impact: Vector2)
var profile: WeaponProfile = Arsenal.PROFILES[0]
var attack_power: float = 100.0
var behavior: RefCounted
var flight_velocity: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO
var shooter_rid: RID
var elapsed: float = 0.0
var resolved: bool = false

func launch(origin: Vector2, initial_velocity: Vector2, wind: int, shooter: RID, weapon_profile: WeaponProfile = null, power: float = 100.0, control: float = 0.0) -> void:
	attack_power = StatRules.limit("power", power)
	profile = weapon_profile if weapon_profile != null else Arsenal.PROFILES[0]
	behavior = profile.behavior.new()
	elapsed = 0.0
	resolved = false
	global_position = origin
	flight_velocity = initial_velocity
	acceleration = BallisticSolver.acceleration(profile, wind, control)
	shooter_rid = shooter

func _physics_process(delta: float) -> void:
	if resolved:
		return
	var next := BallisticSolver.next_position(global_position, flight_velocity, acceleration, delta)
	var query := PhysicsRayQueryParameters2D.create(global_position, next, 3, [shooter_rid])
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	flight_velocity = BallisticSolver.next_velocity(flight_velocity, acceleration, delta)
	elapsed += delta
	if not hit.is_empty():
		hit = behavior.impact(self, hit)
		global_position = hit.position
		resolve(hit.collider)
		return
	global_position = next
	if not CombatConfig.SHOT_BOUNDS.has_point(global_position) or elapsed >= CombatConfig.SHOT_LIFETIME:
		resolve(null)

func resolve(collider: Object) -> void:
	if resolved:
		return
	resolved = true
	finished.emit(collider, global_position)
	queue_free()

func _draw() -> void:
	var palette := {
		"pulso": {"body": Color("f3d974"), "detail": Color("f2a65a"), "glow": Color("ffe7a2")},
		"lastro": {"body": Color("f59b4d"), "detail": Color("ff7143"), "glow": Color("ffd7a3")},
		"risco": {"body": Color("7de3a6"), "detail": Color("324d48"), "glow": Color("dfffe9")},
		"trinca": {"body": Color("bb8cf6"), "detail": Color("e6d4ff"), "glow": Color("f1d4ff")},
		"sonda": {"body": Color("7bd1ff"), "detail": Color("1f7cb8"), "glow": Color("dff5ff")},
	}
	var weapon_style: Dictionary = palette.get(profile.id, {"body": Color("d7c49d"), "detail": Color("e0895d"), "glow": Color("ffe195")}) as Dictionary
	var base: Color = profile.tint if profile.tint != Color.WHITE else Color(weapon_style["body"])
	var glow: Color = Color(weapon_style["glow"])
	var power := clampf(float(elapsed) / maxf(0.01, CombatConfig.SHOT_LIFETIME), 0.0, 1.0)
	draw_circle(Vector2.ZERO, profile.projectile_size + 4.0, Color(base, 0.16))
	draw_circle(Vector2.ZERO, profile.projectile_size, base)
	draw_circle(Vector2.ZERO, maxf(2.0, profile.projectile_size * 0.4), glow)
	if profile.id == "trinca":
		draw_arc(Vector2.ZERO, profile.projectile_size + 6.0, 0.0, TAU, 12, Color(glow, 0.45), 2)
	elif profile.id == "sonda":
		draw_line(Vector2.ZERO, Vector2(0, -profile.projectile_size - 8.0), glow, 2)
	elif profile.id == "lastro":
		draw_circle(Vector2.ZERO, profile.projectile_size + 2.0, Color(base, 0.3))
	if power > 0.75:
		draw_circle(Vector2.ZERO, profile.projectile_size + 9.0, Color(glow, 0.12))
