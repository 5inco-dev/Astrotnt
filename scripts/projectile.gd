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
	draw_circle(Vector2.ZERO, profile.projectile_size + 4, Color(profile.tint, 0.2))
	draw_circle(Vector2.ZERO, profile.projectile_size, profile.tint)
