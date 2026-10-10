extends CanvasLayer

signal control_changed(source: String, action: String, pressed: bool)
signal preparation_requested
signal restart_requested
signal weapon_selected(id: String)
signal cancel_requested
signal aim_assist_requested

var arsenal_open: bool = false
var arsenal_button: Button
var aim_button: Button
var arsenal_panel: Panel
var weapon_buttons: Array[Button] = []
var close_button: Button
var selected_id: String = "pulso"

var enabled: bool = true
var touch_actions: Dictionary = {}
var pads: Dictionary = {}
var root: Control
var status: Label
var health: Label
var details: Label
var power: ProgressBar
var power_text: Label
var message: Label
var preparation: Button
var restart: Button
var last_size := Vector2.ZERO
# REINICIAR/PREPARAR need a second tap during a match; after the match ends one tap is enough.
var armed: String = ""
var armed_left: float = 0.0
var finished: bool = false

func _ready() -> void:
	# Keep the HUD in screen space and above all world/camera content on Android.
	layer = 10
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# Explicit viewport sizing owns this root; anchors must not override it.
	root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	root.position = Vector2.ZERO
	root.size = get_viewport().get_visible_rect().size
	var panel := Panel.new()
	panel.position = Vector2(20, 16)
	panel.size = Vector2(670, 148)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	status = make_label(Vector2(36, 24), 24)
	health = make_label(Vector2(36, 63), 22)
	details = make_label(Vector2(36, 104), 20)
	message = make_label(Vector2(720, 24), 24)
	message.add_theme_color_override("font_color", Color("ffe195"))
	power = ProgressBar.new()
	power.size = Vector2(260, 18)
	power.show_percentage = false
	power.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(power)
	power_text = make_label(Vector2.ZERO, 18)
	for action in ["left", "right", "up", "down", "fire"]:
		var pad := Panel.new()
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color("23475d") if action != "fire" else Color("775327")
		style.set_corner_radius_all(16)
		style.set_border_width_all(2)
		style.border_color = Color("668396")
		pad.add_theme_stylebox_override("panel", style)
		root.add_child(pad)
		pads[action] = pad
		var label := Label.new()
		label.text = {"left":"←", "right":"→", "up":"ÂNGULO +", "down":"ÂNGULO −", "fire":"DISPARAR"}[action]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 24 if action in ["left", "right"] else 20)
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pad.add_child(label)
	restart = Button.new()
	restart.text = "REINICIAR"
	restart.size = Vector2(180, 56)
	restart.add_theme_font_size_override("font_size", 22)
	restart.pressed.connect(func() -> void: request_action("restart"))
	root.add_child(restart)
	preparation = Button.new()
	preparation.text = "PREPARAR"
	preparation.size = Vector2(180, 56)
	preparation.add_theme_font_size_override("font_size", 22)
	preparation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(preparation)
	build_arsenal()
	layout()

func make_label(point: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = point
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)
	return label

func layout() -> void:
	last_size = get_viewport().get_visible_rect().size
	# All positions below are relative to a "safe" origin/size so nothing sits
	# under a notch or rounded corner; root.position carries the whole HUD
	# subtree past the unsafe edge in one shift.
	var insets := SafeArea.insets(get_window())
	var origin := Vector2(insets.left, insets.top)
	var viewport_size := last_size - Vector2(insets.left + insets.right, insets.top + insets.bottom)
	root.position = origin
	root.size = viewport_size
	var bottom := viewport_size.y - 120.0
	pads.left.position = Vector2(24, bottom)
	pads.right.position = Vector2(144, bottom)
	pads.down.position = Vector2(viewport_size.x - 520, bottom)
	pads.up.position = Vector2(viewport_size.x - 370, bottom)
	pads.fire.position = Vector2(viewport_size.x - 210, bottom)
	for action in pads:
		pads[action].size = Vector2(110, 96) if action in ["left", "right"] else Vector2(140, 96)
	pads.fire.size = Vector2(186, 96)
	power.position = Vector2(viewport_size.x - 292, bottom - 32)
	power_text.position = power.position - Vector2(0, 28)
	restart.position = Vector2(viewport_size.x - 204, 24)
	preparation.position = Vector2(viewport_size.x - 420, 24)
	message.position = Vector2(36, 182)
	arsenal_button.position = Vector2(viewport_size.x - 444, 90)
	aim_button.position = Vector2(viewport_size.x - 444, 160)
	arsenal_panel.position = (viewport_size - arsenal_panel.size) * 0.5

func request_action(action: String) -> void:
	var settled: bool = armed == action and armed_left <= CombatConfig.CONFIRM_SECONDS - CombatConfig.CONFIRM_MIN_DELAY
	if finished or settled:
		disarm()
		if action == "restart":
			restart_requested.emit()
		else:
			preparation_requested.emit()
		return
	if armed == action:
		return
	armed = action
	armed_left = CombatConfig.CONFIRM_SECONDS
	refresh_action_buttons()

func disarm() -> void:
	armed = ""
	armed_left = 0.0
	refresh_action_buttons()

func refresh_action_buttons() -> void:
	restart.text = "CONFIRMAR?" if armed == "restart" else "REINICIAR"
	preparation.text = "CONFIRMAR?" if armed == "preparation" else "PREPARAR"
	restart.modulate = Color(1.0, 0.85, 0.4) if armed == "restart" else Color.WHITE
	preparation.modulate = Color(1.0, 0.85, 0.4) if armed == "preparation" else Color.WHITE

func _process(delta: float) -> void:
	if last_size != get_viewport().get_visible_rect().size:
		cancel_contacts()
		layout()
	if armed != "":
		armed_left -= delta
		if armed_left <= 0.0:
			disarm()
	for action in pads:
		pads[action].modulate = Color.WHITE if enabled else Color(0.55,0.55,0.55)
		if touch_actions.values().has(action):
			pads[action].modulate = Color(1.3,1.3,1.3)

func update_state(players: Array[CombatPlayer], turns: TurnManager) -> void:
	finished = turns.phase == TurnManager.Phase.FINISHED
	var player: CombatPlayer = players[turns.active_index]
	selected_id = player.weapon.profile.id
	arsenal_button.text = "ARMA: " + player.weapon.profile.title
	arsenal_button.disabled = not enabled
	for index in range(weapon_buttons.size()):
		var profile: WeaponProfile = Arsenal.PROFILES[index]
		weapon_buttons[index].text = ("✓ " if profile.id == selected_id else "") + profile.title
	health.text = "P1 %s %d/%d  |  P2 %s %d/%d HP" % [players[0].character.title, players[0].hp, players[0].max_hp, players[1].character.title, players[1].hp, players[1].max_hp]
	status.text = "TURNO %d   ·   PLAYER %d" % [turns.turn_number, player.player_number]
	details.text = "Ângulo: %02d°    |    %s" % [roundi(player.angle), WindSystem.label(turns.wind)]
	power.value = player.weapon.power * 100.0
	power_text.text = "FORÇA %d%% · segure e solte" % roundi(power.value)
	if turns.phase == TurnManager.Phase.FINISHED:
		message.text = "EMPATE" if turns.winner == 0 else "PLAYER %d VENCEU" % turns.winner
	elif turns.phase == TurnManager.Phase.PROJECTILE:
		message.text = "Projétil em voo…"
	elif turns.phase == TurnManager.Phase.TRANSITION:
		message.text = "Próximo jogador…"
	elif not player.last_shot.is_empty():
		message.text = "Último tiro: %d° · %d%%" % [roundi(player.last_shot.angle), roundi(float(player.last_shot.power) * 100.0)]
	else:
		message.text = ""

func set_controls_enabled(value: bool) -> void:
	if enabled != value:
		cancel_contacts()
	enabled = value
	if not value:
		set_arsenal_open(false)

func cancel_contacts() -> void:
	# Cancellation never counts as releasing a charged shot.
	touch_actions.clear()
	cancel_requested.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		set_arsenal_open(false)
		cancel_contacts()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var source := "finger_%d" % event.index
		if event.canceled:
			cancel_contacts()
		elif event.pressed:
			if restart.get_global_rect().has_point(event.position):
				request_action("restart")
			else:
				press_at(source, event.position)
		else:
			release_source(source)
	elif event is InputEventScreenDrag:
		# Sliding off a pad cancels that contact. It cannot leave movement stuck.
		var source := "finger_%d" % event.index
		if touch_actions.has(source):
			var pad: Control = pads[touch_actions[source]]
			if not pad.get_global_rect().has_point(event.position):
				if touch_actions[source] == "fire":
					cancel_contacts()
				else:
					release_source(source)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			press_at("mouse", event.position)
		else:
			release_source("mouse")

func press_at(source: String, point: Vector2) -> void:
	if preparation.get_global_rect().has_point(point):
		request_action("preparation")
		return
	if arsenal_open:
		if close_button.get_global_rect().has_point(point):
			set_arsenal_open(false)
			return
		for index in range(weapon_buttons.size()):
			if weapon_buttons[index].get_global_rect().has_point(point):
				weapon_selected.emit(Arsenal.PROFILES[index].id)
				set_arsenal_open(false)
				return
		return
	if enabled and arsenal_button.get_global_rect().has_point(point):
		set_arsenal_open(true)
		return
	if enabled and aim_button.get_global_rect().has_point(point):
		aim_assist_requested.emit()
		return
	if not enabled:
		return
	for action in pads:
		if pads[action].get_global_rect().has_point(point):
			touch_actions[source] = action
			control_changed.emit(source, action, true)
			return

func release_source(source: String) -> void:
	if touch_actions.has(source):
		var action: String = touch_actions[source]
		touch_actions.erase(source)
		control_changed.emit(source, action, false)

func set_aim_label(text: String) -> void:
	aim_button.text = text

func build_arsenal() -> void:
	aim_button = Button.new()
	aim_button.size = Vector2(240, 50)
	aim_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aim_button.add_theme_font_size_override("font_size", 20)
	root.add_child(aim_button)
	arsenal_button = Button.new()
	arsenal_button.size = Vector2(420, 62)
	arsenal_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arsenal_button.add_theme_font_size_override("font_size", 22)
	root.add_child(arsenal_button)
	arsenal_panel = Panel.new()
	arsenal_panel.size = Vector2(520, 460)
	arsenal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(arsenal_panel)
	for index in range(Arsenal.PROFILES.size()):
		var button := Button.new()
		button.position = Vector2(24, 20 + index * 70)
		button.size = Vector2(472, 62)
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_theme_font_size_override("font_size", 24)
		button.add_theme_color_override("font_color", Arsenal.PROFILES[index].tint)
		arsenal_panel.add_child(button)
		weapon_buttons.append(button)
	close_button = Button.new()
	close_button.text = "FECHAR"
	close_button.position = Vector2(24, 380)
	close_button.size = Vector2(472, 62)
	close_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arsenal_panel.add_child(close_button)
	arsenal_panel.hide()

func set_arsenal_open(value: bool) -> void:
	arsenal_open = value and enabled
	arsenal_panel.visible = arsenal_open
	cancel_contacts()
