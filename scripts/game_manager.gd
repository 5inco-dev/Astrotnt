extends Node2D

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
@onready var players: Array[CombatPlayer] = [$Player1, $Player2]
@onready var turns: TurnManager = $TurnManager
@onready var controls: CombatInput = $InputController
@onready var camera: BattleCamera = $CameraController
@onready var hud: CanvasLayer = $HUD
var match_loadouts: Array[CombatLoadout] = []
var changing_scene: bool = false
var transition_left: float = 0.0
var projectile: CombatProjectile
var projectiles: Array[CombatProjectile] = []
var shot_profile: WeaponProfile
var volley_target: Node2D
var blasts: Array[Dictionary] = []
var impact_point := Vector2.ZERO
# 0 = draw a fresh seed for this match; tests/replays may set a fixed value.
var match_seed: int = 0
var aim_mode: int = AimAssist.Mode.NORMAL
var preview: AimPreview
var feel: FeelController
var debug_overlay: DebugOverlay
var volley_damage: Array[int] = [0, 0]
var volley_feedback: Dictionary = {}
var match_stats: Array[Dictionary] = [{}, {}]
var terrain_area_start: float = 0.0
var result_screen: ResultScreen

func _ready() -> void:
	process_physics_priority = -10
	players[1].facing = -1
	hud.control_changed.connect(controls.set_source)
	hud.cancel_requested.connect(cancel_input)
	hud.restart_requested.connect(restart_match)
	hud.weapon_selected.connect(select_weapon)
	hud.preparation_requested.connect(open_preparation)
	hud.aim_assist_requested.connect(cycle_aim_assist)
	feel = FeelController.new()
	add_child(feel)
	feel.setup(camera)
	preview = AimPreview.new()
	preview.players = players
	preview.turns = turns
	add_child(preview)
	if OS.is_debug_build():
		debug_overlay = DebugOverlay.new()
		debug_overlay.game = self
		add_child(debug_overlay)
	result_screen = ResultScreen.new()
	add_child(result_screen)
	result_screen.rematch_requested.connect(restart_match)
	result_screen.preparation_requested.connect(open_preparation)
	result_screen.menu_requested.connect(open_menu)
	if match_loadouts.size() != 2:
		match_loadouts = [CombatLoadout.new(), CombatLoadout.new()]
	for index in range(2):
		if not players[index].apply_loadout(match_loadouts[index]):
			match_loadouts[index] = CombatLoadout.new()
			players[index].apply_loadout(match_loadouts[index])
	if match_seed == 0:
		match_seed = MatchRandom.fresh_seed()
	turns.reset(match_seed)
	apply_aim_mode()
	match_stats = [{"shots": 0, "direct": 0, "near": 0, "damage": 0}, {"shots": 0, "direct": 0, "near": 0, "damage": 0}]
	terrain_area_start = total_terrain_area()
	activate_turn(true)

func cancel_input() -> void:
	controls.clear()
	for player in players:
		player.weapon.cancel()
		player.move_axis = 0.0

func activate_turn(instant: bool = false) -> void:
	if not is_instance_valid(turns) or players.is_empty():
		return
	cancel_input()
	for index in range(players.size()):
		if is_instance_valid(players[index]):
			players[index].active = index == turns.active_index
	if is_instance_valid(players[turns.active_index]):
		camera.follow(players[turns.active_index], instant)
	hud.set_controls_enabled(true)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(turns) or players.size() < 2:
		return
	var player: CombatPlayer = players[turns.active_index]
	if not is_instance_valid(player):
		return
	var command := controls.consume()
	if turns.phase == TurnManager.Phase.AIMING and not hud.arsenal_open:
		player.apply_command(command, delta)
		if command.cancel:
			player.weapon.cancel()
		if command.fire_pressed:
			player.weapon.begin_charge()
		player.weapon.tick(delta)
		if command.fire_released and player.weapon.charging:
			fire(player)
	elif turns.phase == TurnManager.Phase.TRANSITION:
		transition_left -= delta
		if transition_left <= 0.0:
			turns.next_turn()
			activate_turn()
	if hud.arsenal_open:
		cancel_input()
	if is_instance_valid(volley_target) and not projectiles.is_empty():
		var center := Vector2.ZERO
		for shell in projectiles:
			center += shell.global_position
		volley_target.position = volley_target.position.lerp(center / projectiles.size(), 1.0 - exp(-5.0 * delta))
	camera.charging = turns.phase == TurnManager.Phase.AIMING and player.weapon.charging
	var effect_time := feel.effect_delta(delta)
	for blast in blasts:
		blast.left -= effect_time
	blasts = blasts.filter(func(blast: Dictionary) -> bool: return blast.left > 0.0)
	hud.update_state(players, turns)
	queue_redraw()

func select_weapon(id: String) -> void:
	if turns.phase != TurnManager.Phase.AIMING:
		return
	cancel_input()
	players[turns.active_index].weapon.select(id)

func fire(player: CombatPlayer) -> void:
	if hud.arsenal_open or player != players[turns.active_index] or not turns.start_shot():
		return
	shot_profile = player.weapon.profile
	match_stats[turns.active_index].shots += 1
	player.last_shot = {"angle": player.angle, "power": player.weapon.power}
	player.last_impact = Vector2.INF
	volley_damage = [0, 0]
	volley_feedback = {}
	var speed := player.weapon.release_speed()
	feel.on_fire(player, shot_profile)
	player.active = false
	player.move_axis = 0.0
	for index in range(shot_profile.projectile_count):
		var angle := BallisticSolver.volley_angle(player.angle, index, shot_profile.projectile_count, shot_profile.spread)
		var shell: CombatProjectile = PROJECTILE_SCENE.instantiate()
		shell.launch(player.muzzle_origin(), CombatWeapon.aim_vector(angle, player.facing) * speed,
			turns.wind, player.get_rid(), shot_profile, float(player.stats.power), float(player.stats.control))
		shell.finished.connect(on_projectile_finished.bind(shell))
		projectiles.append(shell)
		add_child(shell)
		shell.reset_physics_interpolation()
	projectile = projectiles[0]
	if projectiles.size() == 1:
		camera.follow(projectile)
	else:
		volley_target = Node2D.new()
		add_child(volley_target)
		volley_target.position = player.muzzle_origin()
		volley_target.reset_physics_interpolation()
		camera.follow(volley_target)
	hud.set_controls_enabled(false)
	controls.clear()

func splash_damage(distance: float) -> int:
	return ExplosionResolver.splash(Arsenal.PROFILES[0], distance)

func on_projectile_finished(collider: Object, point: Vector2, shell: CombatProjectile) -> void:
	if turns.phase != TurnManager.Phase.PROJECTILE or not projectiles.has(shell):
		return
	projectiles.erase(shell)
	# Expiry/out-of-bounds resolves the shot without an artificial air explosion.
	if collider != null:
		impact_point = point
		var hp_before := [players[0].hp, players[1].hp]
		ExplosionResolver.apply(shell.profile, collider, point, players, $Map, shell.attack_power)
		for index in range(2):
			var lost: int = hp_before[index] - players[index].hp
			volley_damage[index] += lost
			if lost > 0:
				feel.on_damage(players[index], lost)
			if index != turns.active_index:
				match_stats[turns.active_index].damage += lost
		feel.on_impact(point, shell.profile, collider)
		var shooter: CombatPlayer = players[turns.active_index]
		var result := ShotFeedback.evaluate(shell.profile, collider, point, shooter, players[1 - turns.active_index])
		if volley_feedback.is_empty() or ShotFeedback.score(result) > ShotFeedback.score(volley_feedback):
			volley_feedback = result
		blasts.append({"point": point, "left": 0.42,
			"radius": shell.profile.explosion_radius, "tint": shell.profile.tint})
	if not projectiles.is_empty():
		return
	if is_instance_valid(volley_target):
		volley_target.queue_free()
	present_volley_result()
	# Resolve victory only after the complete volley, including mutual defeat.
	if players[0].hp == 0 or players[1].hp == 0:
		var winner := 0
		if players[0].hp > 0:
			winner = 1
		elif players[1].hp > 0:
			winner = 2
		turns.finish_match(winner)
		camera.enter_result(players[maxi(0, winner - 1)])
		cancel_input()
		result_screen.show_result(winner, players, match_stats, maxf(0.0, terrain_area_start - total_terrain_area()))
		return
	turns.phase = TurnManager.Phase.TRANSITION
	transition_left = CombatConfig.TRANSITION_SECONDS
	camera.follow(players[1 - turns.active_index])
	camera.hold_impact(volley_feedback.get("point", impact_point), 0.35)

func spawn_text(text: String, point: Vector2, color: Color, size: int = 28) -> void:
	var label := FloatingText.new()
	label.text = text
	label.tint = color
	label.font_size = size
	label.position = point
	add_child(label)

# Damage numbers over each hurt player, then why the shot hit or missed.
func present_volley_result() -> void:
	var shooter: CombatPlayer = players[turns.active_index]
	for index in range(2):
		if volley_damage[index] > 0:
			spawn_text("-%d" % volley_damage[index], players[index].global_position + Vector2(0, -70), Color("ff6b6b"), 34)
	if not volley_feedback.is_empty():
		shooter.last_impact = volley_feedback.point
		spawn_text(ShotFeedback.text(volley_feedback), volley_feedback.point + Vector2(0, -40),
			ShotFeedback.color(volley_feedback), 26)
		if volley_feedback.kind == ShotFeedback.Kind.DIRECT_HIT:
			match_stats[turns.active_index].direct += 1
		elif volley_feedback.kind == ShotFeedback.Kind.NEAR_HIT:
			match_stats[turns.active_index].near += 1
	else:
		spawn_text(ShotFeedback.text({}), shooter.global_position + Vector2(0, -90), ShotFeedback.color({}), 24)

func total_terrain_area() -> float:
	var total := 0.0
	for terrain in $Map.terrains:
		total += terrain.solid_area()
	return total

func open_menu() -> void:
	if changing_scene:
		return
	changing_scene = true
	var next: Node = load("res://scenes/main_menu.tscn").instantiate()
	get_tree().root.add_child(next)
	get_tree().current_scene = next
	queue_free()

func cycle_aim_assist() -> void:
	feel.audio.play(&"click", AudioManager.Category.UI)
	aim_mode = AimAssist.next(aim_mode)
	apply_aim_mode()

func apply_aim_mode() -> void:
	preview.mode = aim_mode
	preview.clear()
	for player in players:
		player.show_guide = aim_mode != AimAssist.Mode.OFF
		player.queue_redraw()
	hud.set_aim_label("MIRA: " + AimAssist.title(aim_mode))

func restart_match() -> void:
	change_scene(false)

func open_preparation() -> void:
	change_scene(true)

func change_scene(preparation: bool) -> void:
	if changing_scene:
		return
	changing_scene = true
	cancel_input()
	replace_scene.call_deferred(preparation)

func replace_scene(preparation: bool) -> void:
	var path := "res://scenes/preparation.tscn" if preparation else "res://scenes/main.tscn"
	var next: Node = load(path).instantiate()
	var copies: Array[CombatLoadout] = []
	for value in match_loadouts:
		copies.append(value.copy())
	if preparation:
		next.loadouts = copies
	else:
		next.match_loadouts = copies
		next.aim_mode = aim_mode
	get_tree().root.add_child(next)
	get_tree().current_scene = next
	queue_free()

func _draw() -> void:
	# Previous impact of the active player: the classic artillery reference mark.
	if turns.phase == TurnManager.Phase.AIMING:
		var mark: Vector2 = players[turns.active_index].last_impact
		if mark.is_finite():
			var tint: Color = Color(players[turns.active_index].tint, 0.85)
			draw_line(mark + Vector2(-10, -10), mark + Vector2(10, 10), tint, 3)
			draw_line(mark + Vector2(-10, 10), mark + Vector2(10, -10), tint, 3)
	for blast in blasts:
		var progress: float = 1.0 - blast.left / 0.42
		var radius: float = lerpf(10.0, blast.radius, progress)
		var color: Color = blast.tint
		draw_circle(blast.point, radius, Color(color, 0.10 * (1.0 - progress)))
		draw_arc(blast.point, radius, 0, TAU, 40, Color(color, 1.0 - progress), 4)
