extends SceneTree

var checks := 0
var failures := 0
var game: Node
var prep: Node

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame

func tap(button: Control) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = button.get_global_rect().get_center()
		event.pressed = pressed
		event.index = 0
		root.push_input(event, true)

func fresh(first: CombatLoadout, second: CombatLoadout = null) -> void:
	if is_instance_valid(current_scene):
		current_scene.queue_free()
		await ticks(2)
	game = load("res://scenes/main.tscn").instantiate()
	var selected: Array[CombatLoadout] = [first.copy(), second.copy() if second != null else CombatLoadout.new()]
	game.match_loadouts = selected
	root.add_child(game)
	current_scene = game
	await ticks(60)

func ray(a: Vector2, b: Vector2) -> Dictionary:
	return game.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(a,b,1))

func run() -> void:
	var ids: Array[String] = []
	check(CharacterCatalog.CHARACTERS.size() == 4, "four characters")
	check(CharacterCatalog.EQUIPMENT.size() == 9, "nine equipment presets")
	for character: CharacterProfile in CharacterCatalog.CHARACTERS:
		check(character.valid() and not ids.has(character.id), "valid unique character " + character.id)
		ids.append(character.id)
	ids.clear()
	for item: EquipmentProfile in CharacterCatalog.EQUIPMENT:
		check(item.valid() and not ids.has(item.id), "valid unique equipment " + item.id)
		ids.append(item.id)
	for slot in ["head", "body", "accessory"]:
		check(CharacterCatalog.for_slot(slot).size() == 3, "three options " + slot)
	var invalid := CombatLoadout.new()
	invalid.head = "malha"
	check(not invalid.valid(), "wrong slot rejected")
	invalid.head = "missing"
	check(not invalid.valid(), "unknown ID rejected")
	check(CombatLoadout.from_dict({"character_id": 4}) == null, "invalid serialized types rejected")
	check(not StatRules.valid({"hp": NAN}) and not StatRules.valid({"power": INF},true), "NaN and INF rejected")
	var modifiers: Array[Dictionary] = [{"hp":1e30,"mobility":-1e30,"power":1e30,"resistance":1e30,"control":1e30}]
	var bounded := StatRules.calculate({"hp":1e30,"mobility":-1e30,"power":INF,"resistance":24.0,"control":24.0},modifiers)
	check(bounded.hp == 160 and bounded.mobility == 130 and bounded.resistance == 25 and bounded.control == 25 and is_finite(bounded.power), "clamps handle hostile finite/nonfinite input")
	check(StatRules.damage(-3,100,0) == 0 and StatRules.damage(20,120,25) == 18, "damage formula and nonnegative damage")
	check(StatRules.damage(1,85,100) == 1 and StatRules.damage(20,NAN,INF) == 20, "positive damage cannot become invulnerability")
	check(is_equal_approx(StatRules.wind_multiplier(100),0.75), "control never removes wind")
	# Every catalog combination, including round-trip through stable IDs.
	var combinations := 0
	var all_valid := true
	for character: CharacterProfile in CharacterCatalog.CHARACTERS:
		for head in CharacterCatalog.for_slot("head"):
			for body in CharacterCatalog.for_slot("body"):
				for accessory in CharacterCatalog.for_slot("accessory"):
					for weapon: WeaponProfile in Arsenal.PROFILES:
						var value := CombatLoadout.new()
						value.character_id = character.id
						value.head = head.id
						value.body = body.id
						value.accessory = accessory.id
						value.initial_weapon = weapon.id
						var stats := value.attributes()
						all_valid = all_valid and value.valid() and StatRules.valid(stats) and value.copy().to_dict() == value.to_dict()
						combinations += 1
	check(combinations == 540 and all_valid, "540 character/equipment/weapon combinations valid, bounded and serializable")
	# Production entry scene and real screen touches.
	prep = load("res://scenes/preparation.tscn").instantiate()
	root.add_child(prep)
	current_scene = prep
	await ticks(2)
	check(prep.layer == 10 and prep.root.size == root.get_visible_rect().size, "preparation CanvasLayer and viewport-sized root")
	check(prep.buttons.start.disabled, "cannot start without two confirmations")
	for key in ["character_id", "head", "body", "accessory", "initial_weapon"]:
		tap(prep.buttons[key])
	check(prep.loadouts[0].character_id == "brumo" and prep.loadouts[0].head == "viseira" and prep.loadouts[0].body == "placa" and prep.loadouts[0].accessory == "nucleo" and prep.loadouts[0].initial_weapon == "lastro", "touch selects complete P1 loadout")
	var expected: Dictionary = prep.loadouts[0].attributes()
	check(expected.hp == 120 and expected.mobility == 140 and expected.power == 106 and expected.resistance == 10 and expected.control == 2, "known additive equipment totals")
	check(prep.preview.text.contains("120") and prep.swatch.color == CharacterCatalog.character("brumo").tint, "preview reflects actual stats and character color")
	tap(prep.buttons.confirm)
	check(prep.editing == 1 and prep.confirmed[0], "confirm P1 advances to P2")
	for i in range(3):
		tap(prep.buttons.character_id)
	for i in range(3):
		tap(prep.buttons.initial_weapon)
	tap(prep.buttons.confirm)
	check(not prep.buttons.start.disabled and prep.loadouts[1].initial_weapon == "trinca", "P2 independently chooses character/weapon and confirms")
	# Focus loss clears a pending contact, never selecting on stale release.
	var event := InputEventScreenTouch.new()
	event.position = prep.buttons.character_id.get_global_rect().get_center()
	event.pressed = true
	root.push_input(event,true)
	prep._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	event.pressed = false
	root.push_input(event,true)
	check(prep.loadouts[1].character_id == "lume" and prep.contacts.is_empty(), "preparation focus loss cancels held touch")
	tap(prep.buttons.start)
	await ticks(65)
	game = current_scene
	check(game.players[0].max_hp == 120 and game.players[0].hp == 120 and game.players[0].stats == expected, "starting applies loadout to battle")
	check(game.players[0].weapon.profile.id == "lastro" and game.players[1].weapon.profile.id == "trinca", "both initial weapons applied")
	check(game.hud.layer == 10 and game.hud.root.size == root.get_visible_rect().size and game.hud.health.text.contains("120/120"), "Android HUD invariant and variable HP")
	check(game.players[0].is_on_floor() and game.players[1].is_on_floor(), "configured characters supported before first shot")
	var start_x: float = game.players[0].position.x
	game.controls.set_source("speed", "right", true)
	await ticks(10)
	game.controls.clear()
	check(game.players[0].position.x > start_x + 18 and game.players[0].position.x < start_x + 26, "configured 140px/s speed affects actual movement")
	game.fire(game.players[0])
	check(game.projectile.attack_power == 106 and is_equal_approx(game.projectile.acceleration.x, game.turns.wind * 18.0 * 0.98), "shot snapshots power and control")
	game.projectile.position = game.players[1].position
	game.projectile.resolve(game.players[1])
	check(game.players[1].hp == 95 - roundi(32 * 1.06 * 0.98), "actual impact uses offense and target resistance once")
	await ticks(50)
	game.select_weapon("sonda")
	check(game.players[1].weapon.profile.id == "sonda" and game.players[1].stats.control == 15, "weapon switching preserves character attributes")
	var before: float = game.players[1].position.y
	game.get_node("Map").queue_explosion(game.players[1].position + Vector2(0,26))
	await ticks(30)
	check(game.players[1].position.y > before + 5, "configured character falls when support is removed")
	game.restart_match()
	await ticks(65)
	game = current_scene
	check(game.players[0].hp == 120 and game.players[0].weapon.profile.id == "lastro" and game.players[1].weapon.profile.id == "trinca", "restart restores chosen loadout not current weapon")
	check(game.turns.turn_number == 1 and game.camera.target == game.players[0] and game.controls.sources.is_empty() and not ray(Vector2(1530,680),Vector2(1530,710)).is_empty(), "restart restores terrain turn camera and input")
	# Twenty real weapon/character integrations, including sequential volleys.
	for character: CharacterProfile in CharacterCatalog.CHARACTERS:
		for weapon: WeaponProfile in Arsenal.PROFILES:
			var value := CombatLoadout.new()
			value.character_id = character.id
			value.head = "capuz"
			value.body = "colete"
			value.accessory = "aleta"
			value.initial_weapon = weapon.id
			await fresh(value)
			var ground: DestructibleTerrain = game.get_node("Map").terrains[0]
			var area_before := ground.solid_area()
			game.fire(game.players[0])
			check(game.projectiles.size() == weapon.projectile_count and game.projectile.profile == weapon, character.id + "/" + weapon.id + " launches correct weapon")
			for index in range(game.projectiles.size()):
				var shell: CombatProjectile = game.projectiles[index]
				shell.position = Vector2(1300+index*12,680-index*70)
				shell.flight_velocity = Vector2(0,500)
			await ticks(5)
			if weapon.id == "trinca":
				check(game.turns.phase == TurnManager.Phase.PROJECTILE and game.projectiles.size() > 0, "Trinca waits for remaining configured pellets " + character.id)
			await ticks(90)
			check(game.turns.turn_number == 2 and game.projectiles.is_empty() and ground.solid_area() < area_before, "real impacts deform terrain and advance once " + character.id + "/" + weapon.id)
	# Victory and simultaneous death with non-default max HP.
	var heavy := CombatLoadout.new()
	heavy.character_id = "brumo"
	heavy.initial_weapon = "trinca"
	await fresh(heavy,heavy)
	game.players[1].hp = 1
	game.fire(game.players[0])
	var volley: Array = game.projectiles.duplicate()
	for shell: CombatProjectile in volley:
		shell.set_physics_process(false)
	volley[0].position = game.players[1].position
	volley[0].resolve(game.players[1])
	check(game.turns.phase == TurnManager.Phase.PROJECTILE and game.players[1].hp == 0, "death at variable max HP waits for entire volley")
	volley[1].resolve(null)
	volley[2].resolve(null)
	check(game.turns.winner == 1 and game.turns.phase == TurnManager.Phase.FINISHED, "variable HP victory")
	await fresh(heavy,heavy)
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
	await ticks(1)
	check(game.turns.winner == 0 and game.hud.message.text == "EMPATE", "variable HP mutual defeat")
	game.open_preparation()
	await ticks(5)
	prep = current_scene
	check(prep.loadouts[0].character_id == "brumo" and prep.buttons.start.disabled, "prepare returns choices for editing and requires confirmation")
	for i in range(100):
		prep.choose("character_id")
		prep.choose("head")
		prep.choose("body")
		prep.choose("accessory")
		prep.choose("initial_weapon")
	check(prep.loadouts[0].valid() and StatRules.valid(prep.loadouts[0].attributes()), "500 repeated preparation changes remain valid")
	print("RESULT: ",checks," phase3 checks, ",failures," failure(s); 540 combinations")
	quit(1 if failures else 0)
