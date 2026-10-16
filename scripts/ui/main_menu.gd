extends CanvasLayer

# Landing screen (spec §23). Only JOGAR is real: ARSENAL/PERSONAGEM/INVENTÁRIO/
# MISSÕES/PERFIL have no data behind them yet (no progression system, per
# roadmap Fases D+), so they stay visibly disabled rather than navigate to an
# empty screen or show fabricated stats. Fully keyboard/mouse-free is not a
# goal here; this is the single-device local entry point.
var root: Control
var buttons: Dictionary = {}
var last_size := Vector2.ZERO
var pulse: float = 0.0
var contacts: Dictionary = {}

func _ready() -> void:
	layer = 5
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var background := ColorRect.new()
	background.color = Color("0b1113")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(background)
	var content := Control.new()
	content.size = Vector2(1280, 720)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(content)
	set_meta("content", content)
	var title := Label.new()
	title.text = "FERRO-VELHO"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color("ffe195"))
	title.position = Vector2(0, 150)
	title.size = Vector2(1280, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "GUERRA DE SOBRAS • PLANETA DE LIXO"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("7bd2a8"))
	subtitle.position = Vector2(0, 216)
	subtitle.size = Vector2(1280, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(subtitle)
	var entries: Array = [["jogar", "JOGAR", false], ["arsenal", "ARSENAL", true],
		["personagem", "PERSONAGEM", true], ["inventario", "INVENTÁRIO", true],
		["missoes", "MISSÕES", true], ["perfil", "PERFIL", true]]
	for i in range(entries.size()):
		var id: String = entries[i][0]
		var button := Button.new()
		button.text = entries[i][1]
		button.disabled = entries[i][2]
		button.position = Vector2(440, 310 + i * 62)
		button.size = Vector2(400, 50)
		button.add_theme_font_size_override("font_size", 22)
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(button)
		buttons[id] = button
	var hint := Label.new()
	hint.text = ""
	hint.position = Vector2(0, 680)
	hint.size = Vector2(1280, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color("ffe195"))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(hint)
	set_meta("hint", hint)
	layout()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.canceled:
			contacts.erase(event.index)
		else:
			contact(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag and contacts.has(event.index):
		if not buttons[contacts[event.index]].get_global_rect().has_point(event.position):
			contacts.erase(event.index)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		contact(-1, event.position, event.pressed)

func contact(id: int, point: Vector2, pressed: bool) -> void:
	if pressed:
		for key in buttons:
			if not buttons[key].disabled and buttons[key].get_global_rect().has_point(point):
				contacts[id] = key
				return
	elif contacts.has(id):
		var key: String = contacts[id]
		contacts.erase(id)
		if buttons[key].get_global_rect().has_point(point):
			_on_pressed(key)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		contacts.clear()

func _on_pressed(id: String) -> void:
	if id == "jogar":
		var next: Node = load("res://scenes/preparation.tscn").instantiate()
		get_tree().root.add_child(next)
		get_tree().current_scene = next
		queue_free()
	else:
		var hint: Label = get_meta("hint")
		hint.text = "EM BREVE"

func layout() -> void:
	last_size = get_viewport().get_visible_rect().size
	root.position = Vector2.ZERO
	root.size = last_size
	var content: Control = get_meta("content")
	var insets := SafeArea.insets(get_window())
	var safe_origin := Vector2(insets.left, insets.top)
	var safe_size := last_size - Vector2(insets.left + insets.right, insets.top + insets.bottom)
	var factor := minf(safe_size.x / 1280.0, safe_size.y / 720.0)
	content.scale = Vector2.ONE * factor
	content.position = safe_origin + (safe_size - Vector2(1280, 720) * factor) * 0.5

# Small idle motion on the title so the menu never looks frozen (spec §24).
func _process(delta: float) -> void:
	if last_size != get_viewport().get_visible_rect().size:
		layout()
	pulse += delta
	var content: Control = get_meta("content")
	content.get_child(0).position.y = 150.0 + sin(pulse * 1.4) * 4.0
