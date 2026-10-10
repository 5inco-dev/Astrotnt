class_name AimPreview
extends Node2D

# Draws the aim aid (ASSISTED arc) and the ballistics debug view. Read-only:
# it never changes combat state and only recomputes when its inputs change.
var players: Array[CombatPlayer] = []
var turns: TurnManager
var mode: int = AimAssist.Mode.NORMAL
var debug: bool = false
var result: Dictionary = {}
var key: Array = []
var origin := Vector2.ZERO
var velocity := Vector2.ZERO
var wind_vector := Vector2.ZERO
var radius: float = 0.0
var tint := Color.WHITE

func clear() -> void:
	if not result.is_empty() or not key.is_empty():
		result = {}
		key = []
		queue_redraw()

func _physics_process(_delta: float) -> void:
	if turns == null or players.size() != 2 or turns.phase != TurnManager.Phase.AIMING:
		clear()
		return
	var player: CombatPlayer = players[turns.active_index]
	var weapon := player.weapon
	if not player.active or not ((mode == AimAssist.Mode.ASSISTED and weapon.charging) or debug):
		clear()
		return
	var power := weapon.power
	if not weapon.charging:
		power = float(player.last_shot.get("power", 0.5))
	var new_key := [player.global_position, player.angle, power, turns.wind, weapon.profile.id, player.facing,
		mode, debug, player.stats.control]
	if new_key == key:
		return
	key = new_key
	var profile := weapon.profile
	origin = player.muzzle_origin()
	velocity = BallisticSolver.launch_velocity(profile, player.angle, player.facing, power)
	var accel := BallisticSolver.acceleration(profile, turns.wind, float(player.stats.control))
	wind_vector = Vector2(accel.x, 0.0)
	radius = profile.explosion_radius
	tint = profile.tint
	result = BallisticSolver.predict(origin, velocity, accel, Callable(self, "_ray").bind(player.get_rid()),
		CombatConfig.SHOT_LIFETIME if debug else AimAssist.PREVIEW_SECONDS, 6 if debug else 3)
	queue_redraw()

func _ray(from: Vector2, to: Vector2, shooter: RID) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to, 3, [shooter])
	query.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(query)

func _draw() -> void:
	if result.is_empty():
		return
	var points: PackedVector2Array = result.points
	for index in range(1, points.size()):
		var fade := 1.0 - 0.7 * float(index) / float(points.size())
		draw_circle(points[index], 3.0, Color(tint, 0.9 * fade))
	if not debug:
		return
	# Debug only: exact impact, explosion radius, launch velocity and wind vectors.
	if not result.hit.is_empty():
		draw_arc(result.hit.position, radius, 0, TAU, 48, Color("ff6b6b", 0.8), 2)
		draw_circle(result.hit.position, 5.0, Color("ff6b6b"))
	draw_line(origin, origin + velocity * 0.15, Color("7ee08a"), 3)
	draw_line(origin + Vector2(0, -70), origin + Vector2(0, -70) + wind_vector * 6.0, Color("49cced"), 4)
