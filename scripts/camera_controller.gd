class_name BattleCamera
extends Camera2D

# States: PLAYER (own turn), AIM (charging: gentle push-in), PROJECTILE (follow with
# look-ahead and dynamic zoom-out), IMPACT (brief hold on the explosion), RESULT
# (match over). Cuts never happen: position and zoom are always smoothed.
enum State { PLAYER, AIM, PROJECTILE, IMPACT, RESULT }
const MAX_SHAKE: float = 14.0
const TRAUMA_DECAY: float = 2.2
const LOOK_AHEAD: float = 0.12

var target: Node2D
var charging: bool = false
var result_mode: bool = false
var trauma: float = 0.0
var shake_scale: float = 1.0
var effect_scale: float = 1.0
var hold_point: Vector2 = Vector2.INF
var hold_left: float = 0.0
var rng := RandomNumberGenerator.new()

func _init() -> void:
	# The camera is smoothed every rendered frame in _process; physics
	# interpolation would add a second, competing smoothing layer. Set before
	# entering the tree, otherwise Camera2D forces physics process mode.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

func _ready() -> void:
	limit_left = floori(CombatConfig.CAMERA_LIMITS.position.x)
	limit_top = floori(CombatConfig.CAMERA_LIMITS.position.y)
	limit_right = ceili(CombatConfig.CAMERA_LIMITS.end.x)
	limit_bottom = ceili(CombatConfig.CAMERA_LIMITS.end.y)
	rng.randomize()

func follow(node: Node2D, instant: bool = false) -> void:
	target = node
	result_mode = false
	if instant:
		global_position = target_position()

func enter_result(winner: Node2D) -> void:
	target = winner
	result_mode = true

func hold_impact(point: Vector2, seconds: float) -> void:
	hold_point = point
	hold_left = seconds

func shake(amount: float) -> void:
	trauma = clampf(trauma + amount * shake_scale, 0.0, 1.0)

func current_state() -> State:
	if hold_left > 0.0:
		return State.IMPACT
	if result_mode:
		return State.RESULT
	if target is CombatPlayer:
		return State.AIM if charging else State.PLAYER
	return State.PROJECTILE

func target_position() -> Vector2:
	if not is_instance_valid(target):
		return global_position
	var point := target.global_position
	if target is CombatPlayer:
		point += Vector2(0, -140)
	elif target is CombatProjectile:
		point += target.flight_velocity * LOOK_AHEAD
	return point

func zoom_goal(state: State) -> float:
	match state:
		State.AIM:
			return 1.04
		State.PROJECTILE:
			# Zoom out further the more the shell outruns the camera.
			var lag := (target_position() - global_position).length()
			return lerpf(0.85, 0.65, clampf((lag - 200.0) / 400.0, 0.0, 1.0))
		State.IMPACT:
			return 1.06
		State.RESULT:
			return 1.1
	return 1.0

func _process(delta: float) -> void:
	if hold_left > 0.0:
		hold_left -= delta
		if hold_left <= 0.0:
			hold_point = Vector2.INF
	var goal := hold_point if hold_left > 0.0 else target_position()
	global_position = global_position.lerp(goal, 1.0 - exp(-(5.0 if hold_left > 0.0 else 7.0) * delta))
	zoom = zoom.lerp(Vector2.ONE * zoom_goal(current_state()), 1.0 - exp(-3.0 * delta))
	trauma = maxf(0.0, trauma - TRAUMA_DECAY * delta * effect_scale)
	offset = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * MAX_SHAKE * trauma * trauma
