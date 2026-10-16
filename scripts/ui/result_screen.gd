class_name ResultScreen
extends CanvasLayer

# Shown once a match ends. Only reports numbers the match actually produced —
# no invented XP/coins, since there is no progression system yet (spec §54
# minus rewards). REVANCHE is the default, most accessible action (§56).
signal rematch_requested
signal preparation_requested
signal menu_requested

var root: Control
var title: Label
var subtitle: Label
var columns: Array[VBoxContainer] = []
var rematch_button: Button
var preparation_button: Button
var menu_button: Button
var last_size := Vector2.ZERO
var action_buttons: Dictionary = {}
var contacts: Dictionary = {}

func _ready() -> void:
	layer = 15
	visible = false
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.07, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	set_meta("dim", dim)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	panel.add_child(layout)
	title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	layout.add_child(title)
	subtitle = Label.new()
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("9fb0c0"))
	layout.add_child(subtitle)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(row)
	for i in range(2):
		var column := VBoxContainer.new()
		column.custom_minimum_size = Vector2(240, 0)
		row.add_child(column)
		columns.append(column)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(buttons)
	rematch_button = make_button(buttons, "REVANCHE", 260)
	preparation_button = make_button(buttons, "PREPARAR", 220)
	menu_button = make_button(buttons, "MENU", 180)
	action_buttons = {"rematch": rematch_button, "preparation": preparation_button, "menu": menu_button}
	panel.set("theme_override_styles/panel", make_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	layout_panel(panel)
	set_meta("panel", panel)

func make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172327")
	style.set_corner_radius_all(18)
	style.set_content_margin_all(36)
	style.border_color = Color("22373a")
	style.set_border_width_all(2)
	return style

func make_button(parent: Control, text: String, width: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 64)
	button.add_theme_font_size_override("font_size", 22)
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(button)
	return button

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.canceled:
			contacts.erase(event.index)
		else:
			contact(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag and contacts.has(event.index):
		if not action_buttons[contacts[event.index]].get_global_rect().has_point(event.position):
			contacts.erase(event.index)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		contact(-1, event.position, event.pressed)

func contact(id: int, point: Vector2, pressed: bool) -> void:
	if pressed:
		for key in action_buttons:
			if action_buttons[key].get_global_rect().has_point(point):
				contacts[id] = key
				return
	elif contacts.has(id):
		var key: String = contacts[id]
		contacts.erase(id)
		if action_buttons[key].get_global_rect().has_point(point):
			match key:
				"rematch": rematch_requested.emit()
				"preparation": preparation_requested.emit()
				"menu": menu_requested.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		contacts.clear()

func make_row(column: VBoxContainer, label: String) -> Label:
	var line := Label.new()
	line.text = label
	line.add_theme_font_size_override("font_size", 18)
	column.add_child(line)
	return line

func layout_panel(panel: Control) -> void:
	last_size = get_viewport().get_visible_rect().size
	panel.position = (last_size - panel.size) * 0.5

func _process(_delta: float) -> void:
	if visible and last_size != get_viewport().get_visible_rect().size:
		layout_panel(get_meta("panel"))

func layout_root() -> void:
	var size := get_viewport().get_visible_rect().size
	root.position = Vector2.ZERO
	root.size = size
	var dim: ColorRect = get_meta("dim")
	dim.position = Vector2.ZERO
	dim.size = size

# stats: Array[Dictionary] per player {shots, direct, near, damage}.
# terrain_area: total px² of terrain destroyed this match (shared, not per-player).
func show_result(winner: int, players: Array[CombatPlayer], stats: Array[Dictionary], terrain_area: float) -> void:
	if winner == 0:
		title.text = "EMPATE!"
		title.add_theme_color_override("font_color", Color("ffe195"))
	else:
		title.text = "PLAYER %d VENCEU!" % winner
		title.add_theme_color_override("font_color", players[winner - 1].tint)
	subtitle.text = "Terreno destruído: %d px²" % roundi(terrain_area)
	for i in range(2):
		var column := columns[i]
		for child in column.get_children():
			child.queue_free()
		var header := make_row(column, "PLAYER %d" % (i + 1))
		header.add_theme_font_size_override("font_size", 22)
		header.add_theme_color_override("font_color", players[i].tint)
		var s: Dictionary = stats[i]
		var accuracy := 0.0 if s.shots == 0 else 100.0 * float(s.direct) / float(s.shots)
		make_row(column, "Tiros disparados   %d" % s.shots)
		make_row(column, "Acerto direto      %d" % s.direct)
		make_row(column, "Precisão           %d%%" % roundi(accuracy))
		make_row(column, "Dano causado       %d" % s.damage)
	visible = true
	layout_root()
	var panel: Control = get_meta("panel")
	layout_panel(panel)

func hide_result() -> void:
	visible = false
	contacts.clear()
