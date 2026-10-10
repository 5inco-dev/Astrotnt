class_name CombatWeapon
extends Node

var profile: WeaponProfile = Arsenal.PROFILES[0]
var charging: bool = false
var power: float = 0.0

func select(id: String) -> bool:
	var choice := Arsenal.find(id)
	if choice == null:
		return false
	cancel()
	profile = choice
	return true

func begin_charge() -> void:
	charging = true
	power = 0.0

func tick(delta: float) -> void:
	if charging:
		power = minf(1.0, power + delta / profile.charge_seconds)

func cancel() -> void:
	charging = false
	power = 0.0

func release_speed() -> float:
	var speed := BallisticSolver.speed(profile, power)
	charging = false
	return speed

static func aim_vector(angle_degrees: float, facing: int) -> Vector2:
	return BallisticSolver.aim_vector(angle_degrees, facing)
