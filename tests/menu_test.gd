extends SceneTree

# Fase C: SafeArea math, main menu, result screen (stats + REVANCHE/PREPARAR/MENU).
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

func tap(index: int, point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = index
		event.position = point
		event.pressed = pressed
		root.push_input(event, true)

func spawn(seed_value: int = 3131) -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.match_seed = seed_value
	root.add_child(game)
	current_scene = game
	await ticks(30)

func fire_direct_hit() -> void:
	var target: CombatPlayer = game.players[1 - game.turns.active_index]
	game.controls.set_source("t", "fire", true)
	await ticks(15)
	game.controls.set_source("t", "fire", false)
	await ticks(2)
	game.projectile.global_position = target.global_position + Vector2(0, -80)
	game.projectile.flight_velocity = Vector2(0, 500)
	await ticks(20)

func run() -> void:
	check(ProjectSettings.get_setting("display/window/stretch/aspect", "") == "expand", "stretch aspect is expand (no black bars)")
	check(ProjectSettings.get_setting("display/window/handheld/orientation", "") == "sensor_landscape", "orientation is sensor_landscape")
	check(ProjectSettings.get_setting("application/run/main_scene", "") == "res://scenes/main_menu.tscn", "game boots into the main menu")

	# SafeArea: pure math, desktop (no cutout) yields zero insets
	var window := root.get_window()
	var insets: Dictionary = SafeArea.insets(window)
	check(insets.left == 0.0 and insets.top == 0.0 and insets.right == 0.0 and insets.bottom == 0.0, "no cutout on this platform means zero insets")

	# Main menu
	var menu: Node = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await ticks(10)
	check(not menu.buttons.jogar.disabled, "JOGAR is enabled")
	for id in ["arsenal", "personagem", "inventario", "missoes", "perfil"]:
		check(menu.buttons[id].disabled, "%s has no data yet and stays disabled" % id)
	var hint: Label = menu.get_meta("hint")
	check(hint.text == "", "no placeholder claims before any tap")
	tap(1, menu.buttons.arsenal.get_global_rect().get_center())
	await ticks(3)
	check(current_scene == menu, "tapping a disabled button does not navigate")
	tap(1, menu.buttons.jogar.get_global_rect().get_center())
	await ticks(10)
	check(current_scene != menu and "loadouts" in current_scene, "JOGAR opens preparation")
	current_scene.queue_free()
	await ticks(3)

	# Result screen: direct hit, draw impossible here (P2 starts with full HP), so
	# force a decisive win by zeroing P2's HP after a tracked shot.
	await spawn()
	check(not game.result_screen.visible, "result screen hidden during play")
	var start_area: float = game.terrain_area_start
	check(start_area > 0.0, "match records the starting terrain area")
	await fire_direct_hit()
	check(game.match_stats[0].shots == 1 and game.match_stats[0].direct == 1, "a confirmed direct hit is tallied for the shooter")
	check(game.match_stats[0].damage == 20, "damage dealt to the opponent is tallied (Pulso direct = 20)")
	await ticks(400)
	game.players[1].hp = 0
	game.turns.finish_match(1)
	game.camera.enter_result(game.players[0])
	game.result_screen.show_result(1, game.players, game.match_stats,
		maxf(0.0, game.terrain_area_start - game.total_terrain_area()))
	await ticks(3)
	check(game.result_screen.visible, "show_result reveals the screen")
	check(game.result_screen.title.text == "PLAYER 1 VENCEU!", "title names the winner")
	var p1_column: VBoxContainer = game.result_screen.columns[0]
	var found_shots := false
	var found_accuracy := false
	for child in p1_column.get_children():
		if child is Label:
			if child.text.contains("Tiros disparados") and child.text.contains("1"):
				found_shots = true
			if child.text.contains("Precisão") and child.text.contains("100"):
				found_accuracy = true
	check(found_shots, "P1 column shows the real shot count")
	check(found_accuracy, "P1 column shows 100% accuracy for a single direct hit")
	check(game.result_screen.subtitle.text.begins_with("Terreno destruído:"), "shows real destroyed terrain area, not a placeholder")

	# Draw: no fabricated winner
	game.result_screen.show_result(0, game.players, game.match_stats, 0.0)
	await ticks(2)
	check(game.result_screen.title.text == "EMPATE!", "mutual defeat shows a draw, not a fake winner")

	# REVANCHE keeps loadouts and aim mode; restores hidden result screen
	game.result_screen.show_result(1, game.players, game.match_stats, 0.0)
	await ticks(2)
	game.aim_mode = AimAssist.Mode.ASSISTED
	var rematch_point: Vector2 = game.result_screen.rematch_button.get_global_rect().get_center()
	tap(2, rematch_point)
	await ticks(20)
	check(current_scene != game and "match_loadouts" in current_scene, "REVANCHE restarts the match (same loadouts)")
	check(current_scene.aim_mode == AimAssist.Mode.ASSISTED, "REVANCHE preserves the aim assist mode")
	check(not current_scene.result_screen.visible, "new match starts with the result screen hidden")
	game = current_scene
	await ticks(10)

	# MENU from the result screen goes back to the main menu, not preparation
	game.turns.finish_match(2)
	game.result_screen.show_result(2, game.players, game.match_stats, 0.0)
	await ticks(2)
	tap(3, game.result_screen.menu_button.get_global_rect().get_center())
	await ticks(20)
	check("buttons" in current_scene and "jogar" in current_scene.buttons, "MENU returns to the main menu")

	print("RESULT: %d failure(s)" % failures)
	quit(1 if failures else 0)
