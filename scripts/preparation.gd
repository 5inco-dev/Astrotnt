extends CanvasLayer

var loadouts: Array[CombatLoadout] = [CombatLoadout.new(), CombatLoadout.new()]
var editing: int = 0
var confirmed: Array[bool] = [false, false]
var switching: bool = false
var root: Control
var content: Control
var buttons: Dictionary = {}
var contacts: Dictionary = {}
var title: Label
var preview: Label
var swatch: ColorRect
var last_size := Vector2.ZERO

func _ready() -> void:
	layer = 10
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# Explicit viewport sizing owns this root; anchors must not override it.
	root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var background := ColorRect.new()
	background.color = Color("101b29")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(background)
	content = Control.new()
	content.size = Vector2(1280,720)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(content)
	title = label_at(Vector2(40,24), 30)
	var hint := label_at(Vector2(40,82), 20)
	hint.text = "Toque nas opções para alternar. Confirme os dois jogadores antes de iniciar."
	for i in range(5):
		var key: String = ["character_id", "head", "body", "accessory", "initial_weapon"][i]
		button_at(key, Vector2(40,140+i*82), Vector2(610,68))
	button_at("p1", Vector2(720,24), Vector2(230,56))
	button_at("p2", Vector2(974,24), Vector2(230,56))
	button_at("confirm", Vector2(40,594), Vector2(610,72))
	button_at("start", Vector2(710,594), Vector2(500,72))
	buttons.start.text = "INICIAR PARTIDA"
	swatch = ColorRect.new()
	swatch.position = Vector2(1090,145)
	swatch.size = Vector2(70,90)
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(swatch)
	preview = label_at(Vector2(710,140), 22)
	layout()
	refresh()

func label_at(point: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = point
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(label)
	return label

func button_at(key: String, point: Vector2, size_value: Vector2) -> void:
	var button := Button.new()
	button.position = point
	button.size = size_value
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_theme_font_size_override("font_size", 23)
	content.add_child(button)
	buttons[key] = button

func layout() -> void:
	last_size = get_viewport().get_visible_rect().size
	root.position = Vector2.ZERO
	root.size = last_size
	# Background (full rect) may sit under a notch; the 1280x720 letterboxed
	# content must not, so it is fit and centered inside the safe rect instead.
	var insets := SafeArea.insets(get_window())
	var safe_origin := Vector2(insets.left, insets.top)
	var safe_size := last_size - Vector2(insets.left + insets.right, insets.top + insets.bottom)
	var factor := minf(safe_size.x / 1280.0, safe_size.y / 720.0)
	content.scale = Vector2.ONE * factor
	content.position = safe_origin + (safe_size - Vector2(1280,720) * factor) * 0.5
	contacts.clear()

func _process(_delta: float) -> void:
	if last_size != get_viewport().get_visible_rect().size:
		layout()

func refresh() -> void:
	var value := loadouts[editing]
	var character := CharacterCatalog.character(value.character_id)
	var stats := value.attributes()
	title.text = "PREPARAÇÃO · PLAYER %d" % (editing+1)
	buttons.p1.text = "PLAYER 1" + (" ✓" if confirmed[0] else "")
	buttons.p2.text = "PLAYER 2" + (" ✓" if confirmed[1] else "")
	buttons.character_id.text = "Personagem: " + character.title + "  ›"
	for slot in ["head", "body", "accessory"]:
		buttons[slot].text = {"head":"Cabeça", "body":"Corpo", "accessory":"Acessório"}[slot] + ": " + CharacterCatalog.equipment(value.get(slot)).title + "  ›"
	buttons.initial_weapon.text = "Arma inicial: " + Arsenal.find(value.initial_weapon).title + "  ›"
	buttons.confirm.text = "CONFIRMAR PLAYER %d" % (editing+1)
	buttons.start.disabled = not (confirmed[0] and confirmed[1])
	swatch.color = character.tint
	preview.text = ("%s\n\nHP: %d\nMobilidade: %.0f px/s\nPotência: %.0f%%\nResistência: %.0f%%\nControle: %.0f%%\n\n%s\n\nControle reduz o vento.\nEquipamentos alteram estes totais." %
		[character.title, stats.hp, stats.mobility, stats.power, stats.resistance, stats.control, character.description])

func choose(key: String) -> void:
	if switching:
		return
	if key in ["p1", "p2"]:
		editing = 0 if key == "p1" else 1
	elif key == "confirm":
		confirmed[editing] = true
		if editing == 0:
			editing = 1
	elif key == "start":
		if confirmed[0] and confirmed[1]:
			switching = true
			start_match.call_deferred()
	else:
		var choices: Array[String] = []
		if key == "character_id":
			for item: CharacterProfile in CharacterCatalog.CHARACTERS:
				choices.append(item.id)
		elif key == "initial_weapon":
			for item: WeaponProfile in Arsenal.PROFILES:
				choices.append(item.id)
		elif key in ["head", "body", "accessory"]:
			for item in CharacterCatalog.for_slot(key):
				choices.append(item.id)
		if choices.is_empty():
			return
		var value := loadouts[editing]
		value.set(key, choices[(choices.find(value.get(key)) + 1) % choices.size()])
		confirmed[editing] = false
	refresh()

func start_match() -> void:
	if not loadouts[0].valid() or not loadouts[1].valid():
		switching = false
		return
	var game: Node = load("res://scenes/main.tscn").instantiate()
	var selected: Array[CombatLoadout] = [loadouts[0].copy(), loadouts[1].copy()]
	game.match_loadouts = selected
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	queue_free()

func _input(event: InputEvent) -> void:
	if switching:
		return
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
		contacts.clear()
		if buttons[key].get_global_rect().has_point(point):
			choose(key)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		contacts.clear()
