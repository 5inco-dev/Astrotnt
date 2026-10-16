extends Node2D

const TERRAIN_SCRIPT := preload("res://scripts/destructible_terrain.gd")
var terrains: Array[StaticBody2D] = []
var pending_explosions: Array[Dictionary] = []
var flush_scheduled: bool = false

func _ready() -> void:
	# One continuous ground with walkable slopes, plus two elevated platforms.
	add_surface(PackedVector2Array([Vector2(0,700), Vector2(620,700), Vector2(780,630),
		Vector2(1040,630), Vector2(1220,700), Vector2(2000,700),
		Vector2(2000,920), Vector2(0,920)]), Color("5a4130"), true)
	add_surface(PackedVector2Array([Vector2(140,490), Vector2(350,490),
		Vector2(350,514), Vector2(140,514)]), Color("7c5a38"), true)
	add_surface(PackedVector2Array([Vector2(1660,475), Vector2(1880,475),
		Vector2(1880,499), Vector2(1660,499)]), Color("7c5a38"), true)
	add_surface(PackedVector2Array([Vector2(-40,-1200), Vector2(0,-1200),
		Vector2(0,920), Vector2(-40,920)]), Color("253437"))
	add_surface(PackedVector2Array([Vector2(2000,-1200), Vector2(2040,-1200),
		Vector2(2040,920), Vector2(2000,920)]), Color("253437"))

	# Visible bedrock preserves the lower map boundary after deep excavation.
	add_surface(PackedVector2Array([Vector2(0,920), Vector2(2000,920),
		Vector2(2000,960), Vector2(0,960)]), Color("253437"))

func queue_explosion(point: Vector2, radius: float = CombatConfig.CRATER_RADIUS) -> void:
	pending_explosions.append({"point": point, "radius": radius})
	if not flush_scheduled:
		flush_scheduled = true
		flush_explosions.call_deferred()

func flush_explosions() -> void:
	for point in pending_explosions:
		for terrain in terrains:
			terrain.carve(point.point, point.radius)
	pending_explosions.clear()
	flush_scheduled = false

func add_surface(points: PackedVector2Array, color: Color, destructible: bool = false) -> void:
	if destructible:
		var terrain := TERRAIN_SCRIPT.new()
		# Prepare shapes before registering the body in the physics world.
		terrain.build(points, color)
		add_child(terrain)
		terrains.append(terrain)
		return
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionPolygon2D.new()
	shape.polygon = points
	body.add_child(shape)
	var visual := Polygon2D.new()
	visual.polygon = points
	visual.color = color
	body.add_child(visual)
	add_child(body)

func _draw() -> void:
	for x in range(0, 2001, 100):
		draw_line(Vector2(x, -200), Vector2(x, 920), Color(0.5,0.7,0.9,0.04))
	for y in range(-200, 921, 100):
		draw_line(Vector2(0, y), Vector2(2000, y), Color(0.5,0.7,0.9,0.04))
