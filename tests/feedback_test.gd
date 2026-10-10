extends SceneTree

# Determinism (MatchRandom/WindSystem) and shot feedback (numbers, verdict, marker).
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

func texts() -> Array[String]:
	var found: Array[String] = []
	for child in game.get_children():
		if child is FloatingText:
			found.append(child.text)
	return found

func spawn(seed_value: int = 0) -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.match_seed = seed_value
	root.add_child(game)
	current_scene = game
	await ticks(30)

func fire_and_resolve(hit: bool) -> void:
	var target: CombatPlayer = game.players[1 - game.turns.active_index]
	game.controls.set_source("t", "fire", true)
	await ticks(12)
	game.controls.set_source("t", "fire", false)
	await ticks(2)
	if hit:
		game.projectile.global_position = target.global_position + Vector2(0, -80)
		game.projectile.flight_velocity = Vector2(0, 500)
	else:
		game.projectile.global_position = Vector2(-100, -100)
		game.projectile.flight_velocity = Vector2(-100, 0)
	await ticks(20)

func run() -> void:
	# MatchRandom
	var a := MatchRandom.new(12345)
	var b := MatchRandom.new(12345)
	var c := MatchRandom.new(54321)
	var same := true
	var differs := false
	for i in range(50):
		var x := a.int_range(-5, 5)
		same = same and x == b.int_range(-5, 5)
		differs = differs or x != c.int_range(-5, 5)
	check(same, "same seed reproduces the same sequence")
	check(differs, "different seed changes the sequence")
	a.reseed(12345)
	check(a.seed_value == 12345 and a.int_range(-5, 5) == MatchRandom.new(12345).int_range(-5, 5), "reseed restarts sequence and records seed")
	check(MatchRandom.fresh_seed() >= 0, "fresh seed is non-negative")

	# WindSystem
	check(WindSystem.arrows(0) == "—" and WindSystem.arrows(-1) == "←" and WindSystem.arrows(2) == "→", "weak wind arrows")
	check(WindSystem.arrows(-3) == "←←" and WindSystem.arrows(4) == "→→" and WindSystem.arrows(5) == "→→→" and WindSystem.arrows(-5) == "←←←", "medium and strong wind arrows")
	check(WindSystem.label(0) == "— VENTO CALMO" and WindSystem.label(-5) == "←←← VENTO FORTE (5)" and WindSystem.label(3) == "→→ VENTO MÉDIO (3)", "wind labels")
	var rolled := MatchRandom.new(99)
	var in_range := true
	for i in range(500):
		var w := WindSystem.roll(rolled)
		in_range = in_range and absi(w) <= CombatConfig.MAX_WIND
	check(in_range, "wind stays within configured range")
	var t1 := TurnManager.new()
	var t2 := TurnManager.new()
	t1.reset(777)
	t2.reset(777)
	check(t1.wind == t2.wind and t1.random.seed_value == 777, "turn manager wind is seeded through MatchRandom")
	t1.free()
	t2.free()

	# Match seed
	await spawn(555)
	check(game.turns.random.seed_value == 555 and game.match_seed == 555, "explicit match seed is used")
	var replay := MatchRandom.new(555)
	check(game.turns.wind == WindSystem.roll(replay), "first wind follows the seed")
	game.queue_free()
	await ticks(3)
	await spawn(0)
	var first_seed: int = game.match_seed
	check(first_seed != 0 and game.turns.random.seed_value == first_seed, "seed 0 draws a fresh recorded seed")
	game.queue_free()
	await ticks(3)
	await spawn(0)
	check(game.match_seed != first_seed, "new match gets a different seed")

	# ShotFeedback (pure)
	var p1: CombatPlayer = game.players[0]
	var p2: CombatPlayer = game.players[1]
	var profile: WeaponProfile = Arsenal.PROFILES[0]
	var direct := ShotFeedback.evaluate(profile, p2, p2.global_position, p1, p2)
	var near := ShotFeedback.evaluate(profile, null, p2.global_position + Vector2(-30, 0), p1, p2)
	var far_short := ShotFeedback.evaluate(profile, null, p2.global_position + Vector2(-500, 0), p1, p2)
	var far_long := ShotFeedback.evaluate(profile, null, p2.global_position + Vector2(400, 0), p1, p2)
	check(direct.kind == ShotFeedback.Kind.DIRECT_HIT and ShotFeedback.text(direct) == "DIRECT HIT", "direct hit verdict")
	check(near.kind == ShotFeedback.Kind.NEAR_HIT and ShotFeedback.text(near) == "NEAR HIT  -30 px", "near hit short verdict")
	check(far_short.kind == ShotFeedback.Kind.MISS and ShotFeedback.text(far_short) == "MISS  -500 px", "miss short verdict")
	check(ShotFeedback.text(far_long) == "MISS  +400 px", "miss long verdict")
	# P2 shoots leftwards: landing right of P1 fell short, left of P1 went long.
	check(p2.facing == -1, "P2 faces left")
	var mirrored_short := ShotFeedback.evaluate(profile, null, p1.global_position + Vector2(40, 0), p2, p1)
	var mirrored_long := ShotFeedback.evaluate(profile, null, p1.global_position + Vector2(-40, 0), p2, p1)
	check(mirrored_short.offset == -40.0 and mirrored_long.offset == 40.0, "offset sign follows shooter facing")
	var closer := ShotFeedback.evaluate(profile, null, p2.global_position + Vector2(-30, 0), p1, p2)
	var farther := ShotFeedback.evaluate(profile, null, p2.global_position + Vector2(-60, 0), p1, p2)
	check(ShotFeedback.score(direct) > ShotFeedback.score(closer) and ShotFeedback.score(closer) > ShotFeedback.score(farther)
		and ShotFeedback.score(farther) > ShotFeedback.score(far_short), "volley score ranks direct > near > miss, closer first")
	check(ShotFeedback.text({}) == "FORA DO MAPA", "off-map verdict")

	# Integration: direct hit shows damage number, verdict and marker
	await fire_and_resolve(true)
	var found := texts()
	check(found.has("-20") and found.has("DIRECT HIT"), "damage number and direct hit verdict appear")
	check(p2.hp == 80, "damage unchanged by presentation")
	check(p1.last_shot.has("angle") and float(p1.last_shot.power) > 0.0 and p1.last_impact.is_finite(), "last shot and impact are recorded")
	await ticks(150)
	check(texts().is_empty(), "floating texts free themselves")
	# P2 turn: its own aid is empty; P1's aid shown when it is P1's turn again
	check(game.turns.active_index == 1 and game.hud.message.text == "", "opponent has no last-shot aid yet")
	await fire_and_resolve(false)
	check(texts().has("FORA DO MAPA"), "off-map shot reports it")
	await ticks(150)
	check(game.turns.active_index == 0, "turn returns to P1")
	check(game.hud.message.text.begins_with("Último tiro: "), "HUD shows P1 last shot")
	check(game.hud.details.text.contains("VENTO"), "HUD shows wind label")
	print("RESULT: %d failure(s)" % failures)
	quit(1 if failures else 0)
