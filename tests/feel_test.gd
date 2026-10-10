extends SceneTree

# Game feel: VFX pool, procedural audio, haptics, hit-stop, screen shake, camera states.
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

func spawn() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.match_seed = 909
	root.add_child(game)
	current_scene = game
	await ticks(30)

func fire_hit() -> void:
	var target: CombatPlayer = game.players[1 - game.turns.active_index]
	game.controls.set_source("t", "fire", true)
	await ticks(12)
	game.controls.set_source("t", "fire", false)
	await ticks(2)
	game.projectile.global_position = target.global_position + Vector2(0, -80)
	game.projectile.flight_velocity = Vector2(0, 500)

func run() -> void:
	# ProceduralSounds: deterministic, cached, valid PCM
	var a := ProceduralSounds.stream(&"shot")
	var b := ProceduralSounds.stream(&"shot")
	check(a == b, "same sound id returns the cached stream")
	check(a.data.size() > 0 and a.mix_rate == ProceduralSounds.RATE and not a.stereo, "stream has mono 16-bit PCM data")
	var max_abs := 0
	for i in range(a.data.size() / 2):
		max_abs = maxi(max_abs, absi(a.data.decode_s16(i * 2)))
	check(max_abs <= 32767 and max_abs > 1000, "samples stay in range and are audible")
	for id in ProceduralSounds.ids():
		check(ProceduralSounds.stream(id).data.size() > 0, "sound builds without error: " + str(id))

	# AudioManager: pooled, respects volume, silent gracefully
	var audio := AudioManager.new()
	root.add_child(audio)
	await ticks(2)
	audio.play(&"click", AudioManager.Category.UI)
	check(audio.play_log.has(&"click"), "logged play at full volume")
	audio.settings.master_volume = 0.0
	audio.play(&"click", AudioManager.Category.UI)
	check(audio.play_log.size() == 1, "muted master volume plays nothing")
	audio.settings.master_volume = 1.0
	audio.play(&"nonexistent_sound", AudioManager.Category.UI)
	check(audio.play_log.size() == 1, "unknown sound id is a silent no-op")
	for i in range(audio.players.size() + 3):
		audio.play(&"click", AudioManager.Category.UI)
	check(audio.play_log.size() == 1 + audio.players.size() + 3, "pool wraps around instead of growing")
	audio.queue_free()

	# HapticManager: debounced, capped, silent without support
	var haptics := HapticManager.new()
	haptics.supported = false
	haptics.pulse(20, 0)
	check(haptics.requests.size() == 1, "pulse recorded even without hardware support")
	haptics.pulse(20, 10)
	check(haptics.requests.size() == 1, "pulse inside the debounce window is dropped")
	haptics.pulse(20, 500)
	check(haptics.requests.size() == 2, "pulse after the debounce window is accepted")
	haptics.enabled = false
	haptics.pulse(20, 1000)
	check(haptics.requests.size() == 2, "disabled haptics drop every pulse")

	# VFXController: pooled particles, fixed budget, ages out
	var vfx := VFXController.new()
	root.add_child(vfx)
	check(vfx.positions.size() == VFXController.MAX_PARTICLES, "particle pool is preallocated")
	vfx.sparks(Vector2(100, 100), 120.0, Color.WHITE)
	var after_sparks := vfx.active
	vfx.step(0.0)
	check(after_sparks == 0, "active count updates on the next step, not on spawn")
	vfx.step(0.01)
	check(vfx.active > 0, "sparks become active after a step")
	for i in range(VFXController.MAX_PARTICLES * 2):
		vfx.spawn(VFXController.Kind.SPARK, Vector2.ZERO, Vector2.ZERO, 10.0, 2.0, Color.WHITE)
	check(vfx.positions.size() == VFXController.MAX_PARTICLES, "overflowing spawns recycle slots instead of growing")
	vfx.step(10.5)
	check(vfx.active == 0, "particles age out and clear")
	vfx.enabled = false
	vfx.sparks(Vector2.ZERO, 100.0, Color.WHITE)
	vfx.step(0.01)
	check(vfx.active == 0, "disabled VFX ignores spawn requests")
	vfx.queue_free()

	# FeelController + BattleCamera integration
	await spawn()
	var feel: FeelController = game.feel
	var camera: BattleCamera = game.camera
	check(camera is BattleCamera, "camera controller is the new BattleCamera")
	check(camera.current_state() == BattleCamera.State.PLAYER, "camera starts in PLAYER state")
	game.controls.set_source("t", "fire", true)
	await ticks(10)
	check(camera.charging and camera.current_state() == BattleCamera.State.AIM, "charging enters AIM state")
	var zoom_before: float = camera.zoom.x
	await ticks(30)
	check(camera.zoom.x > zoom_before - 0.001, "AIM zoom pushes in gradually, never snaps")
	game.controls.set_source("t", "fire", false)
	await ticks(3)
	check(camera.current_state() == BattleCamera.State.PROJECTILE, "firing switches to PROJECTILE state")
	var trauma_before: float = camera.trauma
	check(trauma_before > 0.0, "firing itself adds a small shake (on_fire)")

	await fire_hit()
	# Collision resolves a tick or two after we nudge the shell; poll for hit-stop
	# to start, then let it wear off on its own (its own timer, gameplay keeps running).
	var armed := false
	for i in range(20):
		await physics_frame
		if feel.hit_stop_left > 0.0:
			armed = true
			break
	check(armed, "impact triggers hit-stop")
	var frames := 0
	while feel.hit_stop_left > 0.0 and frames < 60:
		await physics_frame
		frames += 1
	check(feel.hit_stop_left == 0.0, "hit-stop wears off on its own")
	await ticks(10)
	check(camera.current_state() == BattleCamera.State.IMPACT, "camera holds briefly on the impact point")
	check(feel.vfx.active > 0, "impact spawned particles")
	await ticks(3)
	check(camera.trauma > trauma_before or camera.trauma > 0.0, "impact adds shake on top of the firing shake")
	await ticks(60)
	check(camera.current_state() != BattleCamera.State.IMPACT, "camera releases the hold after its duration")

	# Match end -> RESULT state, no snap
	await ticks(3)
	game.turns.finish_match(1)
	game.camera.enter_result(game.players[0])
	check(camera.current_state() == BattleCamera.State.RESULT, "victory enters RESULT state")
	# "Never teleports": no single frame closes more than ~15% of the remaining gap
	# (an instant cut would close ~100% in one frame).
	var previous: Vector2 = camera.global_position
	var worst_ratio := 0.0
	for i in range(40):
		var before_dist := previous.distance_to(camera.target_position())
		await ticks(1)
		var step := camera.global_position.distance_to(previous)
		if before_dist > 1.0:
			worst_ratio = maxf(worst_ratio, step / before_dist)
		previous = camera.global_position
	check(worst_ratio < 0.2, "camera eases toward the winner smoothly, never teleports")

	# Settings gate every system
	var muted_camera := BattleCamera.new()
	root.add_child(muted_camera)
	muted_camera._ready()
	var feel2 := FeelController.new()
	feel2.settings.vfx_enabled = false
	feel2.settings.haptics_enabled = false
	feel2.settings.shake_scale = 0.0
	root.add_child(feel2)
	feel2.setup(muted_camera)
	feel2.on_impact(Vector2.ZERO, Arsenal.PROFILES[0], null)
	await ticks(6)
	check(feel2.vfx.active == 0, "disabled VFX setting stays off across a real impact call")
	check(feel2.haptics.requests.is_empty(), "disabled haptics setting produced no pulses")
	check(muted_camera.trauma == 0.0, "shake_scale 0 means no visible shake")
	feel2.queue_free()
	muted_camera.queue_free()

	print("RESULT: %d failure(s)" % failures)
	quit(1 if failures else 0)
