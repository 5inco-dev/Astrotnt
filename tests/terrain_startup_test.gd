extends SceneTree

# No shot, no crater and no long settling period before checking spawn support.
var failures: int = 0
var checks: int = 0
var game: Node2D

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

func verify_startup() -> void:
	game = current_scene
	var map: Node2D = game.get_node("Map")
	# Freeze characters at their authored spawn; inspect geometry immediately
	# after _ready(), then actual physics after the first world synchronization.
	var frozen_positions: Array[Vector2] = []
	for player: CombatPlayer in game.players:
		player.set_physics_process(false)
		frozen_positions.append(player.position)
	check(map.terrains.size() == 3, "three initial terrain surfaces exist")
	var ground: DestructibleTerrain = map.terrains[0]
	check(not ground.chunks.is_empty() and ground.solid_area() > 460000.0,
		"ground has substantial geometry immediately after scene ready")
	for player: CombatPlayer in game.players:
		var covered := false
		var point := Vector2(player.position.x, 704)
		for chunk: Dictionary in ground.chunks.values():
			for polygon: PackedVector2Array in chunk.polygons:
				if Geometry2D.is_point_in_polygon(point, polygon):
					covered = true
		check(covered, "initial draw geometry covers ground under Player %d" % player.player_number)
	await ticks(2)
	for player: CombatPlayer in game.players:
		for dx in [-15.0, 0.0, 15.0]:
			var origin := Vector2(player.position.x + dx, 680)
			var query := PhysicsRayQueryParameters2D.create(origin, origin + Vector2(0, 40), 1)
			var hit := game.get_world_2d().direct_space_state.intersect_ray(query)
			check(not hit.is_empty(), "solid spawn support P%d offset %s before any shot" % [player.player_number, dx])
			if not hit.is_empty():
				check(hit.collider == ground and absf(hit.position.y - 700.0) < 0.1,
					"ray hits original floor, not emergency bottom or player")
		check(player.position == frozen_positions[player.player_number - 1], "spawn has not moved while checking support")
		player.set_physics_process(true)
	await ticks(60)
	for player: CombatPlayer in game.players:
		check(player.is_on_floor() and absf(player.position.y - 674.0) < 1.0,
			"Player %d rests on initial floor instead of falling through" % player.player_number)
	check(game.turns.turn_number == 1 and not is_instance_valid(game.projectile),
		"startup regression did not fire or advance turns")
	check(ground.revision == 0 and map.pending_explosions.is_empty(), "no recut was needed to create ground")

func run() -> void:
	# Reversed winding and a duplicate closing vertex must preserve the same area.
	var outline := PackedVector2Array([Vector2(0,0), Vector2(120,0), Vector2(120,80), Vector2(0,80)])
	for reverse in [false, true]:
		var terrain := DestructibleTerrain.new()
		var points := outline.duplicate()
		if reverse:
			points.reverse()
		points.append(points[0])
		terrain.build(points, Color.WHITE)
		check(absf(terrain.solid_area() - 9600.0) < 1.0, "both windings/closing vertex preserve area before tree entry")
		terrain.free()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await verify_startup()
	game.restart_match()
	await process_frame
	await process_frame
	await verify_startup()
	print("RESULT: ", checks, " startup checks, ", failures, " failure(s)")
	quit(1 if failures else 0)
