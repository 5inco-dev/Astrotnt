class_name DebugOverlay
extends CanvasLayer

# Development-only overlay. Toggle: F3, or four simultaneous touches (Android).
# GameManager only creates it in debug builds (editor or debug export).
var game: Node2D
var label: Label
var touches: Dictionary = {}

func _init() -> void:
	layer = 20
	visible = false

func _ready() -> void:
	label = Label.new()
	label.position = Vector2(300, 250)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)

func toggle() -> void:
	visible = not visible
	game.preview.debug = visible
	if not visible:
		game.preview.clear()

func _process(_delta: float) -> void:
	if visible and is_instance_valid(game):
		label.text = report()

func report() -> String:
	var turns: TurnManager = game.turns
	var player: CombatPlayer = game.players[turns.active_index]
	var revision := 0
	for terrain in game.get_node("Map").terrains:
		revision += terrain.revision
	return "FPS %d | Physics %d Hz | Mem %.1f MB\nTurn %d | Phase %s | P%d\nPos (%.0f, %.0f) | Vel (%.0f, %.0f)\nAngle %.0f° | Power %.0f%% | Wind %d\nProjectiles %d | Terrain rev %d | Seed %d" % [
		Engine.get_frames_per_second(), Engine.physics_ticks_per_second,
		OS.get_static_memory_usage() / 1048576.0, turns.turn_number,
		TurnManager.Phase.keys()[turns.phase], player.player_number,
		player.global_position.x, player.global_position.y, player.velocity.x, player.velocity.y,
		player.angle, player.weapon.power * 100.0, turns.wind,
		game.projectiles.size(), revision, game.match_seed]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		toggle()
	elif event is InputEventScreenTouch:
		if event.canceled or not event.pressed:
			touches.erase(event.index)
		else:
			touches[event.index] = true
			if touches.size() == 4:
				touches.clear()
				toggle()
