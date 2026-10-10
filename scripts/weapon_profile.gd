class_name WeaponProfile
extends Resource

@export var id: String = "pulso"
@export var title: String = "Pulso"
@export var min_speed: float = 300.0
@export var max_speed: float = 1050.0
@export var charge_seconds: float = 1.5
@export var gravity: float = 650.0
@export var wind_factor: float = 1.0
@export var direct_damage: int = 20
@export var splash_max: int = 18
@export var splash_min: int = 4
@export var explosion_radius: float = 120.0
@export var crater_radius: float = 60.0
@export var projectile_count: int = 1
@export var spread: float = 0.0
@export var projectile_size: float = 5.0
@export var tint: Color = Color("ffe195")
@export var penetration: float = 0.0
@export var behavior: Script = preload("res://scripts/projectile_behavior.gd")

func valid() -> bool:
	return (not id.is_empty() and not title.is_empty()
		and min_speed > 0 and max_speed >= min_speed
		and charge_seconds > 0 and gravity >= 0 and wind_factor >= 0
		and direct_damage >= 0 and splash_min >= 0 and splash_max >= splash_min
		and explosion_radius > 0 and crater_radius > 32 and crater_radius <= 128
		and projectile_count >= 1 and projectile_count <= 3 and spread >= 0
		and projectile_size > 0 and penetration >= 0 and penetration < crater_radius
		and behavior != null)
