extends SceneTree

var failures: int = 0
var checks: int = 0
var game: Node2D
var map: Node2D

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame

func fresh_game() -> void:
	if is_instance_valid(game):
		game.queue_free()
		await ticks(2)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	map = game.get_node("Map")
	await ticks(50)

func ray(from: Vector2, to: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	query.hit_from_inside = true
	return game.get_world_2d().direct_space_state.intersect_ray(query)

func area() -> float:
	var value := 0.0
	for terrain: DestructibleTerrain in map.terrains:
		value += terrain.solid_area()
	return value

func geometry_valid() -> bool:
	for terrain: DestructibleTerrain in map.terrains:
		for chunk: Dictionary in terrain.chunks.values():
			if terrain.shape_owner_get_shape_count(chunk.owner_id) != chunk.polygons.size():
				return false
			for index in range(chunk.polygons.size()):
				var polygon: PackedVector2Array = chunk.polygons[index]
				if polygon.size() < 3 or Geometry2D.triangulate_polygon(polygon).is_empty():
					return false
				for point in polygon:
					if not point.is_finite():
						return false
				var shape: ConvexPolygonShape2D = terrain.shape_owner_get_shape(chunk.owner_id, index)
				if shape.points != polygon:
					return false
	return true

func run() -> void:
	await fresh_game()
	var initial_area := area()
	check(map.terrains.size() == 3 and geometry_valid(), "ground and both platforms have matching valid visual/physics polygons")
	check(not ray(Vector2(550, 680), Vector2(550, 730)).is_empty(), "original ground stops rays")
	# Execute the production shot/impact/explosion path, including splash and turns.
	game.fire(game.players[0])
	game.projectile.global_position = Vector2(470, 680)
	game.projectile.flight_velocity = Vector2(0, 600)
	var expected_damage: int = game.splash_damage(game.players[0].global_position.distance_to(Vector2(470, 700)))
	await ticks(12)
	check(area() < initial_area, "real projectile explosion removes solid area")
	check(game.players[0].hp == 100 - expected_damage, "splash damage formula preserved on terrain impact")
	check(game.players[1].hp == 100, "distant player not hurt by splash")
	check(ray(Vector2(470, 690), Vector2(470, 745)).is_empty(), "crater center no longer has original collision")
	check(not ray(Vector2(570, 690), Vector2(570, 710)).is_empty(), "terrain outside crater retains collision")
	check(geometry_valid(), "carved visual polygons exactly match collider polygons")
	await ticks(45)
	check(game.turns.phase == TurnManager.Phase.AIMING and game.turns.active_index == 1,
		"explosion and deferred geometry still advance exactly one turn")
	check(game.camera.target == game.players[1], "camera returns to next player")
	# A real second projectile flies through the old ground, then hits the new bottom.
	var shell: CombatProjectile = load("res://scenes/projectile.tscn").instantiate()
	shell.launch(Vector2(470, 685), Vector2(0, 250), 0, game.players[0].get_rid())
	game.add_child(shell)
	await ticks(9)
	check(is_instance_valid(shell) and shell.position.y > 705, "second projectile crosses removed ground")
	await ticks(25)
	check(not is_instance_valid(shell), "second projectile collides with remaining crater bottom")
	# Overlap and repeat are set subtraction, never filling a previous crater.
	var before := area()
	map.queue_explosion(game.impact_point)
	await ticks(3)
	check(absf(area() - before) < 0.5, "identical repeated crater is idempotent")
	map.queue_explosion(Vector2(500, 735))
	await ticks(3)
	check(area() < before and geometry_valid(), "overlapping crater enlarges opening with valid geometry")
	check(ray(Vector2(470, 690), Vector2(470, 745)).is_empty(), "overlap never refills first opening")
	# Remove support underneath an inactive player; no input or teleport is needed.
	await fresh_game()
	var player: CombatPlayer = game.players[1]
	var old_y := player.position.y
	map.queue_explosion(Vector2(player.position.x, 700))
	await ticks(12)
	check(player.position.y > old_y + 3.0 and not player.active, "inactive character naturally falls after support is removed")
	await ticks(50)
	check(player.is_on_floor() and player.position.y > old_y + 30.0, "character settles on crater bottom instead of floating or embedding")
	# An active player can move on the deformed floor (steep crater walls remain walls).
	game.turns.active_index = 1
	game.activate_turn()
	var old_x := player.position.x
	game.controls.set_source("terrain_test", "right", true)
	await ticks(7)
	game.controls.set_source("terrain_test", "right", false)
	check(player.position.x > old_x + 1.0, "movement still works on remaining crater floor")
	# Buried blast: enclosed cavities in the whole terrain cannot become filled polygons.
	map.queue_explosion(Vector2(800, 810))
	await ticks(3)
	check(ray(Vector2(790, 810), Vector2(810, 810)).is_empty(), "buried circular cavity is actually empty")
	check(not ray(Vector2(800, 590), Vector2(800, 650)).is_empty(), "buried cavity preserves the terrain above it")
	# Platforms can be split or erased; walls and the lower boundary cannot.
	map.queue_explosion(Vector2(240, 490))
	await ticks(3)
	check(ray(Vector2(240, 470), Vector2(240, 530)).is_empty(), "platform opening affects projectile collision")
	check(not ray(Vector2(155, 470), Vector2(155, 530)).is_empty(), "unhit platform fragment remains solid")
	for center in [Vector2(140,490), Vector2(300,490), Vector2(350,490)]:
		map.queue_explosion(center)
	await ticks(3)
	check(map.terrains[1].solid_area() < 0.5, "entire platform can be destroyed")
	for y in [700, 750, 800, 850, 900, 940]:
		map.queue_explosion(Vector2(1500, y))
	await ticks(70)
	check(not ray(Vector2(1500, 918), Vector2(1500, 950)).is_empty(), "indestructible bottom prevents infinite falls")
	map.queue_explosion(Vector2(0, 750))
	await ticks(3)
	check(not ray(Vector2(20, 750), Vector2(-20, 750)).is_empty(), "side wall remains solid")
	# Fixed-seed stress sequence exercises seams, grazing edges and overlapping cuts.
	var rng := RandomNumberGenerator.new()
	rng.seed = 991
	var monotonic := true
	var valid := true
	var max_us: int = 0
	var max_changed: int = 0
	var starting_shapes: int = shape_count()
	for i in range(160):
		var previous := area()
		var center := Vector2(rng.randf_range(610, 1230), rng.randf_range(625, 930))
		# This test measures the same carve work directly, outside physics queries.
		var start := Time.get_ticks_usec()
		for terrain: DestructibleTerrain in map.terrains:
			terrain.carve(center)
			max_changed = maxi(max_changed, terrain.last_changed_chunks)
		max_us = maxi(max_us, Time.get_ticks_usec() - start)
		monotonic = monotonic and area() <= previous + 0.5
		valid = valid and geometry_valid()
		await ticks(1)
	check(monotonic, "160 consecutive craters never add terrain")
	check(valid, "160 consecutive craters preserve finite triangulable matching shapes")
	check(max_changed <= 9, "each blast rebuilds at most nine 64px chunks per surface")
	print("METRICS: max_carve_us=", max_us, " shapes_before=", starting_shapes,
		" shapes_after=", shape_count(), " max_changed_chunks=", max_changed)
	# Physical walk across unbroken chunk seams and ramp transitions after a restart.
	game.restart_match()
	await ticks(55)
	game = current_scene
	map = game.get_node("Map")
	check(absf(area() - initial_area) < 0.5 and geometry_valid(), "restart restores exact initial terrain and collision")
	check(not ray(Vector2(470, 690), Vector2(470, 710)).is_empty(), "restart restores crater position to solid ground")
	check(game.players[0].hp == 100 and game.turns.turn_number == 1, "restart also restores combat state")
	game.controls.set_source("walk", "right", true)
	await ticks(325)
	game.controls.set_source("walk", "right", false)
	check(game.players[0].position.x > 1300 and game.players[0].is_on_floor(),
		"character crosses chunk seams and both original ramp transitions without sticking")
	print("RESULT: ", checks, " checks, ", failures, " failure(s)")
	quit(1 if failures else 0)

func shape_count() -> int:
	var count: int = 0
	for terrain: DestructibleTerrain in map.terrains:
		for chunk: Dictionary in terrain.chunks.values():
			count += chunk.polygons.size()
	return count
