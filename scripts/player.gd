class_name CombatPlayer
extends CharacterBody2D

@export var player_number: int = 1
@export var tint: Color = Color("d39858")
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
	var palette := {
		"naro": {"base": Color("d39858"), "accent": Color("6b3d22"), "trim": Color("f4db7d"), "detail": Color("f5efe9")},
		"brumo": {"base": Color("7bd2a8"), "accent": Color("234f45"), "trim": Color("dfffe9"), "detail": Color("ecf7e8")},
		"vexa": {"base": Color("7bc7d6"), "accent": Color("3f5968"), "trim": Color("fde7a0"), "detail": Color("edf7ff")},
		"lume": {"base": Color("a55d53"), "accent": Color("4a2b21"), "trim": Color("f3d0a3"), "detail": Color("f5efe9")},
	}
	var creature_palette: Dictionary = palette.get(character.id, {"base": Color("d9c39a"), "accent": Color("6e4d46"), "trim": Color("ffe195"), "detail": Color("f5efe9")}) as Dictionary
	var primary: Color = body_color if body_color != Color.WHITE else Color(creature_palette["base"])
	var shadow: Color = primary.darkened(0.4)
	var armor: Color = primary.lightened(0.18)
	var accent: Color = Color(creature_palette["accent"])
	var trim: Color = Color(creature_palette["trim"])
	var detail: Color = Color(creature_palette["detail"])
	draw_circle(Vector2(0, 22), 18, shadow)
	var body := Rect2(-22, -18, 44, 42)
	draw_rect(body, armor)
	draw_rect(Rect2(-16, -30, 32, 12), primary)
	if character.id == "naro":
		draw_rect(Rect2(-24, -7, 12, 26), accent)
		draw_rect(Rect2(12, -7, 12, 26), accent)
		draw_rect(Rect2(-8, -2, 16, 20), trim)
		for sign in [-1, 1]:
			draw_line(Vector2(sign * 10, -12), Vector2(sign * 14, 0), accent, 5)
	elif character.id == "brumo":
		draw_rect(Rect2(-27, -10, 54, 12), accent)
		draw_rect(Rect2(-10, 12, 20, 14), trim)
		draw_line(Vector2(-14, -6), Vector2(-14, 8), trim, 4)
		draw_line(Vector2(14, -6), Vector2(14, 8), trim, 4)
		draw_line(Vector2(-12, -16), Vector2(12, -16), accent, 4)
	elif character.id == "vexa":
		draw_line(Vector2(-15, -8), Vector2(-4, -18), trim, 4)
		draw_line(Vector2(15, -8), Vector2(4, -18), trim, 4)
		draw_line(Vector2(-10, 8), Vector2(10, 8), accent, 4)
		draw_circle(Vector2(0, -16), 8, trim)
		draw_arc(Vector2(0, -16), 10, 0.5, 2.8, 12, accent, 3)
	else:
		draw_rect(Rect2(-18, -20, 36, 10), accent)
		draw_circle(Vector2(-9, -2), 6, trim)
		draw_circle(Vector2(9, -2), 6, trim)
		draw_line(Vector2(-9, 18), Vector2(9, 18), accent, 4)
		draw_line(Vector2(-12, 4), Vector2(0, 12), trim, 4)
		draw_line(Vector2(12, 4), Vector2(0, 12), trim, 4)
	draw_circle(Vector2(facing * 8, -14), 5, Color("0e1826"))
	var eye := Vector2(facing * 8, -10)
	draw_circle(eye, 2.5, detail)
	var hp_rect := Rect2(-25, -34, 50, 5)
	draw_rect(hp_rect, Color("2a3d52"))
	draw_rect(Rect2(hp_rect.position.x, hp_rect.position.y, hp_rect.size.x * float(hp) / float(max_hp), hp_rect.size.y), trim)
	if active and flash > 0.0:
		draw_circle(Vector2.ZERO, 28 + (flash * 14.0), Color(1.0, 1.0, 1.0, flash * 0.45))
	var direction := CombatWeapon.aim_vector(angle, facing)
	var muzzle := Vector2(0, -8) + direction * 30
	var weapon_palette := {
		"pulso": {"body": Color("f3d974"), "detail": Color("f2a65a"), "glow": Color("ffe7a2")},
		"lastro": {"body": Color("f59b4d"), "detail": Color("ff7143"), "glow": Color("ffd7a3")},
		"risco": {"body": Color("7de3a6"), "detail": Color("324d48"), "glow": Color("dfffe9")},
		"trinca": {"body": Color("bb8cf6"), "detail": Color("e6d4ff"), "glow": Color("f1d4ff")},
		"sonda": {"body": Color("7bd1ff"), "detail": Color("1f7cb8"), "glow": Color("dff5ff")},
	}
	var weapon_style: Dictionary = weapon_palette.get(weapon.profile.id, {"body": Color("d7c49d"), "detail": Color("e0895d"), "glow": Color("ffe195")}) as Dictionary
	var body_tint: Color = weapon.profile.tint if weapon.profile.tint != Color.WHITE else Color(weapon_style["body"])
	var dir := Vector2(cos(deg_to_rad(rad_to_deg(direction.angle()))) * facing, -sin(deg_to_rad(rad_to_deg(direction.angle()))))
	var weapon_muzzle = Vector2(0, -8) + dir * 18
	draw_line(Vector2(0, -4), weapon_muzzle, body_tint, 7)
	draw_line(Vector2(0, -4), Vector2(0, -20), weapon_style["detail"], 2)
	draw_circle(weapon_muzzle, 5.0 + weapon.power * 3.5, weapon_style["glow"])
	if weapon.profile.id == "trinca":
		draw_line(Vector2(-8, -4), Vector2(-8, -18), weapon_style["detail"], 3)
		draw_line(Vector2(8, -4), Vector2(8, -18), weapon_style["detail"], 3)
	elif weapon.profile.id == "sonda":
		draw_line(Vector2(0, -16), Vector2(0, -26), weapon_style["glow"], 2)
		draw_circle(Vector2(-6, -18), 3, weapon_style["detail"])
		draw_circle(Vector2(6, -18), 3, weapon_style["detail"])
	elif weapon.profile.id == "lastro":
		draw_rect(Rect2(-5, -18, 10, 18), weapon_style["detail"])
	elif weapon.profile.id == "risco":
		draw_line(Vector2(-10, -8), Vector2(10, -8), weapon_style["glow"], 3)
		draw_line(Vector2(0, -8), Vector2(0, -20), weapon_style["detail"], 3)
	else:
		draw_rect(Rect2(-8, -18, 16, 18), weapon_style["detail"])
	draw_line(Vector2(0, -8), muzzle, body_color.lightened(0.35), 8)
	if active:
		if show_guide:
			draw_line(Vector2(0, -8) + direction * 38, Vector2(0, -8) + direction * 85,
				Color("ffe195"), 2)
		draw_circle(Vector2(0, -48), 5, Color("ffe195"))
	draw_rect(Rect2(-25, -39, 50, 5), Color("29384a"))
	draw_rect(Rect2(-25, -39, 50.0 * hp / max_hp, 5), tint)
