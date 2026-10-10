class_name CombatPlayer
extends CharacterBody2D

@export var player_number: int = 1
@export var tint: Color = Color("49cced")
var loadout := CombatLoadout.new()
var stats: Dictionary = StatRules.BASE.duplicate()
var max_hp: int = 100
var hp: int = 100
var character: CharacterProfile = CharacterCatalog.CHARACTERS[0]
var facing: int = 1
var angle: float = 45.0
var active: bool = false
var move_axis: float = 0.0
# Aim aid: what this player did last turn (angle, power 0..1) and where it landed.
var last_shot: Dictionary = {}
var show_guide: bool = true
var last_impact: Vector2 = Vector2.INF
var flash: float = 0.0
var body_style := StyleBoxFlat.new()
@onready var weapon: CombatWeapon = $Weapon

func apply_loadout(value: CombatLoadout) -> bool:
	if value == null or not value.valid():
		return false
	loadout = value.copy()
	stats = loadout.attributes()
	character = CharacterCatalog.character(loadout.character_id)
	max_hp = int(stats.hp)
	hp = max_hp
	tint = character.tint
	weapon.select(loadout.initial_weapon)
	queue_redraw()
	return true

func apply_command(command: Dictionary, delta: float) -> void:
	move_axis = clampf(float(command.move), -1.0, 1.0) if active else 0.0
	if not active:
		return
	if not is_zero_approx(move_axis):
		facing = 1 if move_axis > 0 else -1
	angle = clampf(angle + float(command.aim) * CombatConfig.ANGLE_SPEED * delta,
		CombatConfig.MIN_ANGLE, CombatConfig.MAX_ANGLE)

func _physics_process(delta: float) -> void:
	velocity.x = move_axis * float(stats.mobility) if active else 0.0
	velocity.y += character.gravity * delta
	move_and_slide()
	flash = maxf(0.0, flash - delta / 0.18)
	position.x = clampf(position.x, 22.0, CombatConfig.MAP_WIDTH - 22.0)
	queue_redraw()

func take_damage(amount: int) -> void:
	hp = maxi(0, hp - maxi(0, amount))
	queue_redraw()

func hit_flash() -> void:
	flash = 1.0

func muzzle_origin() -> Vector2:
	# Start at body center and exclude shooter. This cannot skip a nearby wall.
	return global_position + Vector2(0, -8)

func _draw() -> void:
	var body_color := (tint if hp > 0 else Color("455262")).lerp(Color.WHITE, flash * 0.8)
	# Straining while the shot is fully charged; cosmetic only.
	if active and weapon.charging and weapon.power > 0.6:
		draw_set_transform(Vector2(sin(Time.get_ticks_msec() * 0.08), 0.0) * (weapon.power - 0.6) * 4.0)
	body_style.bg_color = body_color
	body_style.set_corner_radius_all(9)
	draw_style_box(body_style, Rect2(-20, -26, 40, 52))
	# Team outline remains distinguishable even with identical characters.
	var team_color := Color("49cced") if player_number == 1 else Color("f5a36e")
	draw_rect(Rect2(-20,-26,40,52), team_color, false, 2)
	draw_circle(Vector2(facing * 8, -12), 5, Color("0e1826"))
	# Character emblem and equipment are visual only; collision stays 40 x 52.
	var marker := Vector2(-9, 5)
	if character.emblem == 0:
		draw_circle(marker, 4, Color.WHITE)
	elif character.emblem == 1:
		draw_rect(Rect2(marker - Vector2(4,4), Vector2(8,8)), Color.WHITE)
	elif character.emblem == 2:
		draw_line(marker - Vector2(4,4), marker + Vector2(4,4), Color.WHITE, 3)
	else:
		draw_arc(marker, 5, 0, TAU, 12, Color.WHITE, 2)
	for slot in ["head", "body", "accessory"]:
		var item := CharacterCatalog.equipment(loadout.get(slot))
		var center: Vector2 = {"head": Vector2(0,-28), "body": Vector2(7,8), "accessory": Vector2(24,8)}[slot]
		if item.shape == 0:
			draw_line(center - Vector2(5,0), center + Vector2(5,0), item.tint, 3)
		elif item.shape == 1:
			draw_rect(Rect2(center - Vector2(5,4), Vector2(10,8)), item.tint)
		else:
			draw_circle(center, 5, item.tint)
	var direction := CombatWeapon.aim_vector(angle, facing)
	draw_line(Vector2(0, -8), Vector2(0, -8) + direction * 32, body_color.lightened(0.35), 8)
	if active:
		if show_guide:
			draw_line(Vector2(0, -8) + direction * 38, Vector2(0, -8) + direction * 85,
				Color("ffe195"), 2)
		draw_circle(Vector2(0, -48), 5, Color("ffe195"))
	draw_rect(Rect2(-25, -39, 50, 5), Color("29384a"))
	draw_rect(Rect2(-25, -39, 50.0 * hp / max_hp, 5), tint)
