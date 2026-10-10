extends SceneTree

# Mobile package: physics interpolation, camera limits, two-tap REINICIAR/PREPARAR.
var failures: int = 0
var game: Node2D

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

func tap(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 7
		event.position = point
		event.pressed = pressed
		root.push_input(event, true)

func spawn() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await ticks(30)

func run() -> void:
	check(ProjectSettings.get_setting("physics/common/physics_interpolation", false) == true, "physics interpolation enabled")
	await spawn()
	var cam: Camera2D = game.camera
	check(cam.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF, "camera opts out of physics interpolation")
	check(cam.limit_left == -40 and cam.limit_right == 2040 and cam.limit_top == -1200 and cam.limit_bottom == 960, "camera limits match map walls and bedrock")
	# Player against the left wall: the view must not cross the wall line.
	game.players[0].position.x = 22.0
	cam.follow(game.players[0], true)
	await ticks(90)
	var half := root.get_visible_rect().size * 0.5
	check(cam.get_screen_center_position().x - half.x >= -40.0 - 0.5, "camera stays inside left wall")
	game.players[0].position.x = 1978.0
	cam.follow(game.players[0], true)
	await ticks(90)
	check(cam.get_screen_center_position().x + half.x <= 2040.0 + 0.5, "camera stays inside right wall")
	# Interpolation reset does not break a real volley.
	game.players[0].position.x = 420.0
	await ticks(5)
	game.controls.set_source("t", "fire", true)
	await ticks(10)
	game.controls.set_source("t", "fire", false)
	await ticks(3)
	check(game.turns.phase == TurnManager.Phase.PROJECTILE and not game.projectiles.is_empty(), "volley launches with interpolation reset")
	await ticks(700)
	check(game.projectiles.is_empty(), "volley resolves")
	game.queue_free()
	await ticks(3)

	# Mid-match REINICIAR: one tap only arms.
	await spawn()
	var hud = game.hud
	var restart_point: Vector2 = hud.restart.get_global_rect().get_center()
	var prep_point: Vector2 = hud.preparation.get_global_rect().get_center()
	check(not hud.restart.get_global_rect().intersects(hud.preparation.get_global_rect()), "buttons do not overlap")
	var before := game
	var game_script: Script = before.get_script()
	tap(restart_point)
	await ticks(5)
	check(current_scene == before and hud.armed == "restart" and hud.restart.text == "CONFIRMAR?", "first tap arms restart without restarting")
	tap(restart_point)
	await ticks(5)
	check(current_scene == before and hud.armed == "restart", "instant second tap (debounce) does not confirm")
	# Arming the other button replaces the first.
	tap(prep_point)
	await ticks(5)
	check(hud.armed == "preparation" and hud.restart.text == "REINICIAR" and hud.preparation.text == "CONFIRMAR?", "arming preparation disarms restart")
	# Timeout disarms.
	await ticks(200)
	check(hud.armed == "" and hud.preparation.text == "PREPARAR", "armed state expires")
	# Confirmed restart.
	tap(restart_point)
	await ticks(20)
	tap(restart_point)
	await ticks(5)
	check(current_scene != before and current_scene.get_script() == game_script, "second tap after delay restarts match")
	# Confirmed preparation.
	game = current_scene
	await ticks(10)
	hud = game.hud
	prep_point = hud.preparation.get_global_rect().get_center()
	tap(prep_point)
	await ticks(20)
	tap(prep_point)
	await ticks(5)
	check("loadouts" in current_scene and not ("match_loadouts" in current_scene), "confirmed preparation opens preparation scene")

	# After the match ends a single tap is enough.
	await spawn()
	hud = game.hud
	game.turns.finish_match(1)
	await ticks(5)
	var ended := game
	tap(hud.preparation.get_global_rect().get_center())
	await ticks(5)
	check(current_scene != ended and "loadouts" in current_scene, "single tap works after match end")
	print("RESULT: %d failure(s)" % failures)
	quit(1 if failures else 0)
