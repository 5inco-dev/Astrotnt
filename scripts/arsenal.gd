class_name Arsenal
extends RefCounted

# Lazy loading avoids resource/script initialization cycles through loadouts.
static var _profiles: Array[WeaponProfile] = []
static var PROFILES: Array[WeaponProfile]:
	get:
		if _profiles.is_empty():
			for id in ["pulso", "lastro", "risco", "trinca", "sonda"]:
				_profiles.append(load("res://resources/weapons/%s.tres" % id))
		return _profiles

static func find(id: String) -> WeaponProfile:
	for profile: WeaponProfile in PROFILES:
		if profile.id == id:
			return profile
	return null
