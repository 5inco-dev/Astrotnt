class_name VFXController
extends Node2D

# Pooled particles drawn in one node: a fixed ring buffer, no node per particle.
# Purely cosmetic (its own RNG), never touches gameplay state.
enum Kind { SPARK, DEBRIS, SMOKE, FLASH }
const MAX_PARTICLES: int = 200
const GRAVITY: float = 800.0

var enabled: bool = true
var active: int = 0
var next_slot: int = 0
var positions := PackedVector2Array()
var velocities := PackedVector2Array()
var ages := PackedFloat32Array()
var spans := PackedFloat32Array()
var sizes := PackedFloat32Array()
var kinds := PackedInt32Array()
var colors := PackedColorArray()
var rng := RandomNumberGenerator.new()

func _init() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	z_index = 8
	positions.resize(MAX_PARTICLES)
	velocities.resize(MAX_PARTICLES)
	ages.resize(MAX_PARTICLES)
	spans.resize(MAX_PARTICLES)
	sizes.resize(MAX_PARTICLES)
	kinds.resize(MAX_PARTICLES)
	colors.resize(MAX_PARTICLES)
	ages.fill(1.0)
	spans.fill(1.0)
	rng.randomize()

func spawn(kind: int, point: Vector2, velocity: Vector2, life: float, size: float, color: Color) -> void:
	if not enabled:
		return
	var slot := next_slot
	next_slot = (next_slot + 1) % MAX_PARTICLES
	positions[slot] = point
	velocities[slot] = velocity
	ages[slot] = 0.0
	spans[slot] = life
	sizes[slot] = size
	kinds[slot] = kind
	colors[slot] = color

func flash(point: Vector2, radius: float) -> void:
	spawn(Kind.FLASH, point, Vector2.ZERO, 0.12, radius * 1.1, Color.WHITE)

func sparks(point: Vector2, radius: float, tint: Color) -> void:
	for i in range(int(lerpf(10.0, 22.0, clampf(radius / 160.0, 0.0, 1.0)))):
		var direction := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
		spawn(Kind.SPARK, point, direction * rng.randf_range(200.0, 520.0), rng.randf_range(0.25, 0.5), 2.0, tint.lightened(0.3))

func debris(point: Vector2, radius: float) -> void:
	for i in range(int(lerpf(8.0, 18.0, clampf(radius / 160.0, 0.0, 1.0)))):
		var direction := Vector2.UP.rotated(rng.randf_range(-1.2, 1.2))
		var color := Color("46667a") if i % 2 == 0 else Color("344a57")
		spawn(Kind.DEBRIS, point, direction * rng.randf_range(120.0, 380.0), rng.randf_range(0.6, 1.0), rng.randf_range(3.0, 6.0), color)

func smoke(point: Vector2, radius: float) -> void:
	for i in range(4):
		spawn(Kind.SMOKE, point + Vector2(rng.randf_range(-0.3, 0.3) * radius, 0), Vector2(rng.randf_range(-14.0, 14.0), -rng.randf_range(20.0, 50.0)),
			rng.randf_range(0.8, 1.2), radius * 0.25, Color(0.62, 0.68, 0.74))

func muzzle(point: Vector2, direction: Vector2, tint: Color) -> void:
	for i in range(6):
		var spread := direction.rotated(rng.randf_range(-0.35, 0.35))
		spawn(Kind.SPARK, point, spread * rng.randf_range(180.0, 380.0), rng.randf_range(0.12, 0.25), 2.0, tint)

func clear() -> void:
	ages.fill(1.0)
	active = 0
	queue_redraw()

func step(delta: float) -> void:
	var alive := 0
	for i in range(MAX_PARTICLES):
		if ages[i] >= spans[i]:
			continue
		ages[i] += delta
		if ages[i] >= spans[i]:
			continue
		alive += 1
		var velocity := velocities[i]
		if kinds[i] == Kind.DEBRIS or kinds[i] == Kind.SPARK:
			velocity.y += GRAVITY * delta * (1.0 if kinds[i] == Kind.DEBRIS else 0.4)
		velocities[i] = velocity
		positions[i] += velocity * delta
	if alive > 0 or active > 0:
		queue_redraw()
	active = alive

func _draw() -> void:
	for i in range(MAX_PARTICLES):
		if ages[i] >= spans[i]:
			continue
		var progress := ages[i] / spans[i]
		var fade := 1.0 - progress
		var color := colors[i]
		match kinds[i]:
			Kind.SPARK:
				draw_line(positions[i], positions[i] - velocities[i] * 0.03, Color(color, fade), sizes[i])
			Kind.DEBRIS:
				draw_rect(Rect2(positions[i] - Vector2.ONE * sizes[i] * 0.5, Vector2.ONE * sizes[i]), Color(color, minf(1.0, fade * 1.6)))
			Kind.SMOKE:
				draw_circle(positions[i], sizes[i] * (1.0 + progress * 1.5), Color(color, 0.28 * fade))
			Kind.FLASH:
				draw_circle(positions[i], sizes[i] * (0.6 + 0.4 * progress), Color(1, 1, 1, 0.55 * fade))
