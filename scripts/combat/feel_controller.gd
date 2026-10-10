class_name FeelController
extends Node

# Presentation of shots and impacts (VFX, audio, haptics, camera kick, hit-stop).
# Reads combat events, never changes them. Timeline per impact (spec §27):
#   0 ms flash + boom + haptic + hit-stop | 20 ms shake | 50 ms debris/smoke/sparks
# Effect time freezes during hit-stop; gameplay time never does.
const HIT_STOP_MIN: float = 0.05
const HIT_STOP_MAX: float = 0.09

var settings: FeelSettings = FeelSettings.new()
var vfx: VFXController = VFXController.new()
var audio: AudioManager = AudioManager.new()
var haptics: HapticManager = HapticManager.new()
var camera: BattleCamera
var hit_stop_left: float = 0.0
var scheduled: Array[Dictionary] = []

func setup(battle_camera: BattleCamera) -> void:
	camera = battle_camera
	audio.settings = settings
	add_child(vfx)
	add_child(audio)
	apply_settings()

func apply_settings() -> void:
	vfx.enabled = settings.vfx_enabled
	haptics.enabled = settings.haptics_enabled
	camera.shake_scale = settings.shake_scale

func strength(profile: WeaponProfile) -> float:
	return clampf(profile.explosion_radius / 160.0, 0.0, 1.0)

# 1.0 normally, 0.0 while the impact frame is held.
func effect_delta(delta: float) -> float:
	return 0.0 if hit_stop_left > 0.0 else delta

func on_fire(player: CombatPlayer, profile: WeaponProfile) -> void:
	var direction := CombatWeapon.aim_vector(player.angle, player.facing)
	vfx.muzzle(player.muzzle_origin() + direction * 34.0, direction, profile.tint)
	audio.play(&"shot", AudioManager.Category.WEAPON, randf_range(0.95, 1.05) * lerpf(1.15, 0.9, strength(profile)))
	haptics.pulse(HapticManager.SHOT_MS)
	camera.shake(0.12)

func on_impact(point: Vector2, profile: WeaponProfile, collider: Object) -> void:
	var power := strength(profile)
	vfx.flash(point, profile.explosion_radius)
	audio.play(&"boom_big" if power >= 0.85 else &"boom_small", AudioManager.Category.IMPACT, lerpf(1.15, 0.9, power))
	haptics.pulse(HapticManager.BIG_IMPACT_MS if power >= 0.85 else HapticManager.IMPACT_MS)
	hit_stop_left = lerpf(HIT_STOP_MIN, HIT_STOP_MAX, power)
	later(0.02, camera.shake.bind(0.25 + 0.45 * power))
	later(0.05, play_aftermath.bind(point, profile, collider))

func play_aftermath(point: Vector2, profile: WeaponProfile, collider: Object) -> void:
	vfx.sparks(point, profile.explosion_radius, profile.tint)
	vfx.smoke(point, profile.explosion_radius)
	if collider is DestructibleTerrain:
		vfx.debris(point, profile.explosion_radius)
		audio.play(&"debris", AudioManager.Category.IMPACT, randf_range(0.9, 1.1))

func on_damage(player: CombatPlayer, _amount: int) -> void:
	player.hit_flash()
	audio.play(&"damage", AudioManager.Category.CHARACTER)

func later(delay: float, action: Callable) -> void:
	scheduled.append({"left": delay, "action": action})

func _process(delta: float) -> void:
	hit_stop_left = maxf(0.0, hit_stop_left - delta)
	var effect := effect_delta(delta)
	camera.effect_scale = 0.0 if hit_stop_left > 0.0 else 1.0
	vfx.step(effect)
	var pending: Array[Dictionary] = []
	for entry in scheduled:
		entry.left -= delta
		if entry.left <= 0.0:
			entry.action.call()
		else:
			pending.append(entry)
	scheduled = pending
