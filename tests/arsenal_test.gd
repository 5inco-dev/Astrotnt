extends SceneTree

var failures := 0
var checks := 0
var game: Node2D

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + label)
	else:
		print("PASS: ", label)

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame

func fresh() -> void:
	if is_instance_valid(game):
		game.restart_match()
		await ticks(4)
		game = current_scene
	else:
		game = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		current_scene = game
	await ticks(60)

func touch(point: Vector2, pressed: bool, index: int = 0) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = pressed
	event.index = index
	root.push_input(event, true)

func tap(point: Vector2) -> void:
	touch(point, true)
	touch(point, false)

func ray(a: Vector2, b: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(a, b, 1)
	query.hit_from_inside = true
	return game.get_world_2d().direct_space_state.intersect_ray(query)

func run() -> void:
	await fresh()
	check(Arsenal.PROFILES.size() == 5, "five registered profiles")
	var ids: Array[String] = []
	for profile: WeaponProfile in Arsenal.PROFILES:
		check(profile.valid() and not ids.has(profile.id), profile.id + " valid unique profile")
		ids.append(profile.id)
		check(Arsenal.find(profile.id) == profile, "registry resolves " + profile.id)
	check(not game.players[0].weapon.select("missing"), "invalid selection rejected")
	# Actual touch selection while another finger is moving/charging cancels inputs.
	touch(game.hud.pads.right.get_global_rect().get_center(), true, 1)
	touch(game.hud.pads.fire.get_global_rect().get_center(), true, 2)
	await ticks(4)
	tap(game.hud.arsenal_button.get_global_rect().get_center())
	await ticks(3)
	var x: float = game.players[0].position.x
	check(game.hud.arsenal_open and not game.players[0].weapon.charging, "panel cancels held fire")
	game.controls.set_source("keyboard", "right", true)
	await ticks(10)
	check(game.players[0].position.x == x, "modal blocks movement including keyboard")
	tap(game.hud.weapon_buttons[1].get_global_rect().get_center())
	touch(game.hud.pads.fire.get_global_rect().get_center(), false, 2)
	touch(game.hud.pads.right.get_global_rect().get_center(), false, 1)
	await ticks(3)
	check(not game.hud.arsenal_open and game.players[0].weapon.profile.id == "lastro", "touch selects and closes")
	check(game.turns.phase == TurnManager.Phase.AIMING and game.projectiles.is_empty(), "modal release never fires")
	for profile: WeaponProfile in Arsenal.PROFILES:
		await fresh()
		check(game.players[0].is_on_floor() and game.players[1].is_on_floor(), "initial support " + profile.id)
		game.select_weapon(profile.id)
		game.players[0].weapon.begin_charge()
		game.players[0].weapon.tick(profile.charge_seconds * 0.5)
		game.fire(game.players[0])
		check(game.projectiles.size() == profile.projectile_count, "real shot count " + profile.id)
		var shell: CombatProjectile = game.projectiles[0]
		check(shell.profile == profile and absf(shell.flight_velocity.length() - (profile.min_speed + profile.max_speed) * 0.5) < 0.01, "selected speed " + profile.id)
		check(shell.acceleration.y == profile.gravity and is_equal_approx(shell.acceleration.x, game.turns.wind * CombatConfig.WIND_ACCELERATION * profile.wind_factor), "selected ballistics " + profile.id)
		game.select_weapon("pulso")
		check(game.players[0].weapon.profile == profile, "selection locked during flight " + profile.id)
		var shells: Array = game.projectiles.duplicate()
		for other: CombatProjectile in shells:
			other.set_physics_process(false)
		var before: int = game.players[1].hp
		shell.position = game.players[1].position
		shell.resolve(game.players[1])
		check(game.players[1].hp == before - profile.direct_damage, "direct damage once " + profile.id)
		if profile.projectile_count > 1:
			check(game.turns.phase == TurnManager.Phase.PROJECTILE and game.projectiles.size() == 2, "first pellet cannot finish turn")
			var target: Node2D = game.camera.target
			shells[1].resolve(null)
			check(game.turns.phase == TurnManager.Phase.PROJECTILE and game.camera.target == target, "second pellet preserves camera target and turn")
			shells[2].resolve(null)
		await ticks(50)
		check(game.turns.phase == TurnManager.Phase.AIMING and game.turns.active_index == 1 and game.turns.turn_number == 2, "all pellets finish exactly one turn " + profile.id)
		# Actual queued crater size, in untouched flat terrain away from players.
		game.get_node("Map").queue_explosion(Vector2(1300, 800), profile.crater_radius)
		await ticks(3)
		check(ray(Vector2(1300,800), Vector2(1300 + profile.crater_radius - 2,800)).is_empty(), "interior empty " + profile.id)
		check(not ray(Vector2(1300 + profile.crater_radius + 2,790), Vector2(1300 + profile.crater_radius + 2,810)).is_empty(), "outside crater solid " + profile.id)
		var victim: CombatPlayer = game.players[1]
		victim.position = Vector2(1300, 600)
		victim.set_physics_process(false)
		victim.hp = 100
		ExplosionResolver.apply(profile, null, victim.position + Vector2(profile.explosion_radius * 0.5,0), game.players, game.get_node("Map"))
		check(victim.hp == 100 - maxi(profile.splash_min, roundi(profile.splash_max * 0.5)), "configured splash falloff " + profile.id)
	# Real swept piercing collision must move burst beneath the original surface.
	await fresh()
	game.select_weapon("sonda")
	game.fire(game.players[0])
	game.projectile.position = Vector2(1300,680)
	game.projectile.flight_velocity = Vector2(0,600)
	await ticks(8)
	check(game.impact_point.y > 735 and game.impact_point.y < 742, "Sonda bursts 40px beneath first terrain hit")
	check(ray(Vector2(1300,695), Vector2(1300,780)).is_empty(), "piercing blast leaves connected opening")
	# All remaining pellets resolve even when the first kills a player.
	await fresh()
	game.select_weapon("trinca")
	game.players[1].hp = 1
	game.fire(game.players[0])
	var volley: Array = game.projectiles.duplicate()
	for shell: CombatProjectile in volley:
		shell.set_physics_process(false)
	volley[0].position = game.players[1].position
	volley[0].resolve(game.players[1])
	check(game.turns.phase == TurnManager.Phase.PROJECTILE, "death waits for remaining pellets")
	volley[1].resolve(null)
	volley[2].resolve(null)
	check(game.turns.phase == TurnManager.Phase.FINISHED and game.turns.winner == 1, "volley victory resolves")
	await fresh()
	game.select_weapon("trinca")
	game.players[0].hp = 1
	game.players[1].hp = 1
	game.players[1].position = game.players[0].position + Vector2(40,0)
	game.fire(game.players[0])
	volley = game.projectiles.duplicate()
	for shell: CombatProjectile in volley:
		shell.set_physics_process(false)
	volley[0].position = game.players[0].position
	volley[0].resolve(game.players[0])
	volley[1].resolve(null)
	volley[2].resolve(null)
	check(game.turns.phase == TurnManager.Phase.FINISHED and game.turns.winner == 0, "mutual defeat gives draw")
	# Real three-pellet terrain hits and their deferred overlapping cuts.
	await fresh()
	game.select_weapon("trinca")
	game.fire(game.players[0])
	var ground: DestructibleTerrain = game.get_node("Map").terrains[0]
	var original_area := ground.solid_area()
	var trajectories: Array[Vector2] = []
	for index in range(game.projectiles.size()):
		var shell: CombatProjectile = game.projectiles[index]
		trajectories.append(shell.flight_velocity.normalized())
		shell.position = Vector2(1280 + index * 18, 680 - index * 12)
		shell.flight_velocity = Vector2(0,600)
	check(trajectories[0] != trajectories[1] and trajectories[1] != trajectories[2], "scatter has distinct angular trajectories")
	await ticks(65)
	check(ground.solid_area() < original_area and game.projectiles.is_empty(), "real staggered scatter impacts carve terrain")
	check(game.turns.turn_number == 2, "real scatter advances once")
	# Piercing may not skip another body along its bounded subsurface segment.
	await fresh()
	game.players[1].position = Vector2(1300,740)
	game.players[1].set_physics_process(false)
	await ticks(2)
	game.select_weapon("sonda")
	game.fire(game.players[0])
	game.projectile.position = Vector2(1300,680)
	game.projectile.flight_velocity = Vector2(0,600)
	await ticks(8)
	check(game.players[1].hp == 78 and game.impact_point.y < 720, "piercing swept segment stops on buried player")
	await fresh()
	game.select_weapon("sonda")
	game.fire(game.players[0])
	game.projectile.position = Vector2(1990,600)
	game.projectile.flight_velocity = Vector2(600,0)
	await ticks(5)
	check(absf(game.impact_point.x - 2000) < 0.1, "piercing does not cross indestructible wall")
	# Expiry and focus cancellation, including panel closing.
	await fresh()
	game.fire(game.players[0])
	game.projectile.position = Vector2(900,100)
	game.projectile.elapsed = CombatConfig.SHOT_LIFETIME
	await ticks(50)
	check(game.turns.turn_number == 2 and game.projectiles.is_empty(), "expiry completes turn")
	game.controls.set_source("held", "fire", true)
	await ticks(5)
	game.hud.set_arsenal_open(true)
	game.hud._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await ticks(2)
	check(not game.hud.arsenal_open and not game.players[1].weapon.charging and game.controls.sources.is_empty(), "focus loss closes arsenal and clears charge")
	game.controls.set_source("held", "fire", false)
	await ticks(2)
	check(game.turns.phase == TurnManager.Phase.AIMING, "return/release after focus loss never shoots")
	# Stress real volley lifecycles, mixed-radius overlapping craters and restarts.
	for sequence in range(15):
		await fresh()
		check(game.players[0].weapon.profile.id == "pulso" and game.players[1].weapon.profile.id == "pulso" and game.projectiles.is_empty(), "restart resets arsenal %d" % sequence)
		for choice in range(20):
			game.select_weapon(Arsenal.PROFILES[choice % 5].id)
		game.select_weapon("trinca")
		game.fire(game.players[0])
		for shell: CombatProjectile in game.projectiles.duplicate():
			shell.position = Vector2(-200,-100)
		await ticks(50)
		check(game.turns.turn_number == 2, "stress volley exits without stuck turn %d" % sequence)
		for crater in range(10):
			game.get_node("Map").queue_explosion(Vector2(800 + crater * 12,700 + crater * 9), Arsenal.PROFILES[crater % 5].crater_radius)
		await ticks(3)
		var valid := true
		for terrain: DestructibleTerrain in game.get_node("Map").terrains:
			for chunk: Dictionary in terrain.chunks.values():
				valid = valid and terrain.shape_owner_get_shape_count(chunk.owner_id) == chunk.polygons.size()
				for polygon: PackedVector2Array in chunk.polygons:
					valid = valid and not Geometry2D.triangulate_polygon(polygon).is_empty()
		check(valid, "mixed overlapping crater geometry %d" % sequence)
	# Restart mid-flight deletes entire volley and restores initial terrain.
	game.select_weapon("trinca")
	game.fire(game.players[1])
	await fresh()
	check(game.projectiles.is_empty() and game.turns.turn_number == 1 and game.players[0].is_on_floor(), "restart during volley restores scene")
	print("RESULT: ", checks, " arsenal checks, ", failures, " failure(s)")
	quit(1 if failures else 0)
