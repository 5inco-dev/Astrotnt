extends SceneTree

# BallisticSolver (single source of kinematics), aim assist modes, debug overlay.
var failures: int = 0
var game: Node2D
var landed: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame

func tap(index: int, point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = index
		event.position = point
		event.pressed = pressed
		root.push_input(event, true)

func spawn() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.match_seed = 4242
	root.add_child(game)
	current_scene = game
	await ticks(30)

func ray(from: Vector2, to: Vector2, shooter: RID) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to, 3, [shooter])
	query.hit_from_inside = true
	return game.get_world_2d().direct_space_state.intersect_ray(query)

func real_impact(profile: WeaponProfile, origin: Vector2, velocity: Vector2, wind: int) -> Vector2:
	var shell: CombatProjectile = load("res://scenes/projectile.tscn").instantiate()
	shell.launch(origin, velocity, wind, game.players[0].get_rid(), profile, 100.0, 0.0)
	landed = {}
	shell.finished.connect(func(_c: Object, point: Vector2) -> void: landed = {"point": point})
	game.add_child(shell)
	for i in range(900):
		await physics_frame
		if not landed.is_empty():
			break
	return landed.get("point", Vector2.INF)

func run() -> void:
	await spawn()
	var pulso: WeaponProfile = Arsenal.PROFILES[0]
	# Pure kinematics
	var accel := BallisticSolver.acceleration(pulso, 3, 0.0)
	check(is_equal_approx(accel.x, 3 * CombatConfig.WIND_ACCELERATION * pulso.wind_factor) and accel.y == pulso.gravity, "acceleration = wind + gravity")
	check(BallisticSolver.acceleration(pulso, -3, 0.0).x == -accel.x, "wind sign flips acceleration")
	check(is_equal_approx(BallisticSolver.acceleration(pulso, 3, 20.0).x, accel.x * 0.8), "control reduces wind acceleration")
	for profile: WeaponProfile in Arsenal.PROFILES:
		check(BallisticSolver.acceleration(profile, 0, 0.0) == Vector2(0.0, profile.gravity), "no wind, gravity only: " + profile.id)
	check(is_equal_approx(BallisticSolver.speed(pulso, 0.0), pulso.min_speed) and is_equal_approx(BallisticSolver.speed(pulso, 1.0), pulso.max_speed) and is_equal_approx(BallisticSolver.speed(pulso, 5.0), pulso.max_speed), "speed spans min..max and clamps power")
	var velocity := BallisticSolver.launch_velocity(pulso, 45.0, 1, 1.0)
	check(is_equal_approx(velocity.length(), pulso.max_speed) and velocity.x > 0.0 and velocity.y < 0.0 and is_equal_approx(velocity.x, -velocity.y), "45 degrees launch goes right and up equally")
	check(is_equal_approx(BallisticSolver.launch_velocity(pulso, 45.0, -1, 1.0).x, -velocity.x), "facing left mirrors x")
	var trinca: WeaponProfile = Arsenal.find("trinca")
	check(is_equal_approx(BallisticSolver.volley_angle(45.0, 0, 3, trinca.spread), 45.0 - trinca.spread) and is_equal_approx(BallisticSolver.volley_angle(45.0, 1, 3, trinca.spread), 45.0) and is_equal_approx(BallisticSolver.volley_angle(45.0, 2, 3, trinca.spread), 45.0 + trinca.spread), "volley angles are centered")
	check(is_equal_approx(BallisticSolver.volley_angle(30.0, 0, 1, 0.0), 30.0), "single shell uses aimed angle")
	check(CombatWeapon.aim_vector(60.0, -1).is_equal_approx(BallisticSolver.aim_vector(60.0, -1)), "weapon aim delegates to solver")

	# Prediction equals real flight (stride 1 exact, stride 6 close)
	var shooter: RID = game.players[0].get_rid()
	var hit_test := Callable(self, "ray").bind(shooter)
	for wind in [0, 4, -4]:
		var origin: Vector2 = game.players[0].muzzle_origin()
		var launch := BallisticSolver.launch_velocity(pulso, 50.0, 1, 0.5)
		var accel_w := BallisticSolver.acceleration(pulso, wind, 0.0)
		var exact := BallisticSolver.predict(origin, launch, accel_w, hit_test, CombatConfig.SHOT_LIFETIME, 1)
		var coarse := BallisticSolver.predict(origin, launch, accel_w, hit_test, CombatConfig.SHOT_LIFETIME, 6)
		var real := await real_impact(pulso, origin, launch, wind)
		check(not exact.hit.is_empty() and exact.hit.position.distance_to(real) < 0.5, "stride 1 prediction matches real impact (wind %d)" % wind)
		check(not coarse.hit.is_empty() and coarse.hit.position.distance_to(real) < 12.0, "stride 6 prediction close to real impact (wind %d)" % wind)
		await ticks(5)
	var offmap := BallisticSolver.predict(Vector2(500, 300), Vector2(0, -3000), Vector2(0, 100), Callable(), 5.0, 6)
	check(offmap.hit.is_empty() and offmap.points.size() < 100, "prediction stops at the shot bounds")

	# Aim assist modes
	var hud = game.hud
	check(game.aim_mode == AimAssist.Mode.NORMAL and hud.aim_button.text == "MIRA: NORMAL" and game.players[0].show_guide, "default is NORMAL with guide")
	var player: CombatPlayer = game.players[0]
	game.controls.set_source("t", "fire", true)
	await ticks(20)
	check(game.preview.result.is_empty(), "NORMAL draws no predicted arc")
	game.controls.set_source("t", "fire", false)
	await ticks(400)
	var point: Vector2 = hud.aim_button.get_global_rect().get_center()
	tap(3, point)
	await ticks(3)
	check(game.aim_mode == AimAssist.Mode.ASSISTED and hud.aim_button.text == "MIRA: ASSISTED", "HUD button cycles to ASSISTED")
	await ticks(60)
	player = game.players[game.turns.active_index]
	game.controls.set_source("t", "fire", true)
	await ticks(20)
	var arc: PackedVector2Array = game.preview.result.get("points", PackedVector2Array())
	check(arc.size() > 3 and arc.size() <= int(AimAssist.PREVIEW_SECONDS * 60.0 / 3.0) + 3, "ASSISTED shows a partial arc while charging")
	var before: PackedVector2Array = arc
	await ticks(15)
	check(game.preview.result.points != before, "arc follows the growing charge")
	game.controls.set_source("t", "fire", false)
	await ticks(3)
	check(game.preview.result.is_empty(), "arc disappears after firing")
	await ticks(400)
	tap(3, hud.aim_button.get_global_rect().get_center())
	await ticks(3)
	check(game.aim_mode == AimAssist.Mode.OFF and not game.players[0].show_guide and not game.players[1].show_guide, "OFF hides the guide")
	game.controls.set_source("t", "fire", true)
	await ticks(20)
	check(game.preview.result.is_empty(), "OFF draws no arc")
	game.controls.set_source("t", "fire", false)
	await ticks(3)
	check(AimAssist.allowed(AimAssist.Mode.ASSISTED, true) == AimAssist.Mode.OFF and AimAssist.allowed(AimAssist.Mode.ASSISTED, false) == AimAssist.Mode.ASSISTED, "ranked rules force OFF")
	check(AimAssist.next(AimAssist.Mode.ASSISTED) == AimAssist.Mode.OFF, "mode cycle wraps")
	# Setting survives restart
	game.aim_mode = AimAssist.Mode.ASSISTED
	game.restart_match()
	await ticks(10)
	check(current_scene.aim_mode == AimAssist.Mode.ASSISTED and current_scene.hud.aim_button.text == "MIRA: ASSISTED", "aim mode survives restart")
	game = current_scene
	await ticks(20)

	# Debug overlay (debug builds only)
	check(OS.is_debug_build() == (game.debug_overlay != null), "overlay exists only in debug builds")
	if game.debug_overlay != null:
		var overlay: DebugOverlay = game.debug_overlay
		check(not overlay.visible and not game.preview.debug, "overlay starts hidden")
		var key := InputEventKey.new()
		key.physical_keycode = KEY_F3
		key.pressed = true
		root.push_input(key, true)
		await ticks(3)
		check(overlay.visible and game.preview.debug and overlay.label.text.contains("FPS") and overlay.label.text.contains("Seed"), "F3 shows overlay with report")
		await ticks(5)
		check(not game.preview.result.is_empty() and not game.preview.result.hit.is_empty(), "debug view predicts full trajectory with collision")
		root.push_input(key, true)
		await ticks(3)
		check(not overlay.visible and game.preview.result.is_empty(), "F3 hides overlay and clears preview")
		for index in range(4):
			var event := InputEventScreenTouch.new()
			event.index = 10 + index
			event.position = Vector2(100 + index * 50, 300)
			event.pressed = true
			root.push_input(event, true)
		await ticks(3)
		check(overlay.visible, "four simultaneous touches toggle overlay")
		for index in range(4):
			var release := InputEventScreenTouch.new()
			release.index = 10 + index
			release.pressed = false
			root.push_input(release, true)
		await ticks(2)
		check(overlay.touches.is_empty(), "touch tracking clears on release")
	print("RESULT: %d failure(s)" % failures)
	quit(1 if failures else 0)
