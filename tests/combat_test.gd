extends SceneTree

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

func touch(index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	# Coordinates are already in viewport space (headless has a virtual window).
	root.push_input(event, true)

func shoot(hit_target: bool) -> void:
	var target: CombatPlayer = game.players[1 - game.turns.active_index]
	game.controls.set_source("test_fire", "fire", true)
	await ticks(12)
	check(game.players[game.turns.active_index].weapon.charging, "charge starts")
	game.controls.set_source("test_fire", "fire", false)
	await ticks(2)
	check(game.turns.phase == TurnManager.Phase.PROJECTILE, "release launches exactly one shot")
	check(game.camera.target == game.projectile, "camera follows projectile")
	# Place the real projectile on a collision course to test ray/damage/turn integration.
	if hit_target:
		game.projectile.global_position = target.global_position + Vector2(0, -80)
		game.projectile.flight_velocity = Vector2(0, 500)
	else:
		game.projectile.global_position = Vector2(-100, -100)
		game.projectile.flight_velocity = Vector2(-100, 0)
	await ticks(65)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await ticks(60)
	check(game.players[0].is_on_floor() and game.players[1].is_on_floor(), "players settle on ground")
	check(game.players[0].hp == 100 and game.players[1].hp == 100, "initial HP")
	check(game.players[0].active and not game.players[1].active, "only P1 active")
	var inactive_x: float = game.players[1].position.x
	var initial_x: float = game.players[0].position.x
	var angle: float = game.players[0].angle
	# Dispatch real screen events, two fingers at once.
	touch(0, game.hud.pads.right.get_global_rect().get_center(), true)
	touch(1, game.hud.pads.up.get_global_rect().get_center(), true)
	await ticks(20)
	touch(0, game.hud.pads.right.get_global_rect().get_center(), false)
	touch(1, game.hud.pads.up.get_global_rect().get_center(), false)
	await ticks(2)
	check(game.players[0].position.x > initial_x, "touch movement")
	check(game.players[0].angle > angle, "multitouch aiming")
	check(game.players[1].position.x == inactive_x, "inactive player does not move")
	game.controls.set_source("test", "fire", true)
	await ticks(4)
	game.hud.cancel_contacts()
	await ticks(4)
	check(not game.players[0].weapon.charging and game.turns.phase == TurnManager.Phase.AIMING,
		"cancel never shoots or leaves charge stuck")
	game.controls.set_source("test", "fire", true)
	await ticks(100)
	check(is_equal_approx(game.players[0].weapon.power, 1.0), "charge capped at 100 percent")
	game.cancel_input()
	await ticks(2)
	var first := TurnManager.new()
	var second := TurnManager.new()
	first.reset()
	second.reset()
	for i in range(20):
		check(first.wind == second.wind, "seeded wind reproduces turn %d" % i)
		first.phase = TurnManager.Phase.TRANSITION
		second.phase = TurnManager.Phase.TRANSITION
		first.next_turn()
		second.next_turn()
	first.free()
	second.free()
	# Isolated real projectile steps against the analytic constant-acceleration result.
	var ballistic: CombatProjectile = load("res://scenes/projectile.tscn").instantiate()
	ballistic.launch(Vector2(900, 0), Vector2(100, -100), 3, game.players[0].get_rid())
	game.add_child(ballistic)
	ballistic.set_physics_process(false)
	for i in range(30):
		ballistic._physics_process(1.0 / 60.0)
	var expected := Vector2(900, 0) + Vector2(100, -100) * 0.5 + Vector2(54, 650) * 0.125
	check(ballistic.position.distance_to(expected) < 0.01, "ballistic position includes gravity and wind")
	var first_position := ballistic.position
	ballistic.launch(Vector2(900, 0), Vector2(100, -100), 3, game.players[0].get_rid())
	for i in range(30):
		ballistic._physics_process(1.0 / 60.0)
	check(ballistic.position == first_position, "same launch reproduces same trajectory")
	ballistic.queue_free()
	# Real terrain collision at high velocity must not tunnel through the ground.
	var shell: CombatProjectile = load("res://scenes/projectile.tscn").instantiate()
	shell.launch(Vector2(1300, 680), Vector2(0, 10000), 0, game.players[0].get_rid())
	game.add_child(shell)
	await ticks(3)
	check(not is_instance_valid(shell), "swept collision catches high-speed terrain hit")
	for hit in range(5):
		await shoot(true)
		check(game.players[1].hp == 100 - 20 * (hit + 1), "direct hit deals exactly 20 HP")
		if hit < 4:
			check(game.turns.active_index == 1, "turn passes to P2 after impact")
			await shoot(false)
			check(game.turns.active_index == 0, "out-of-bounds shot passes back to P1")
	check(game.turns.phase == TurnManager.Phase.FINISHED and game.turns.winner == 1,
		"fifth direct hit ends match with P1 winner")
	check(not game.hud.enabled, "combat controls disabled at match end")
	# Restart via actual Android-style screen touch, with mouse emulation disabled.
	touch(4, game.hud.restart.get_global_rect().get_center(), true)
	await ticks(5)
	game = current_scene
	check(game.players[0].hp == 100 and game.players[1].hp == 100
		and game.turns.turn_number == 1, "touch restart resets health and turns")
	print("RESULT: %d failure(s)" % failures)
	quit(1 if failures else 0)
