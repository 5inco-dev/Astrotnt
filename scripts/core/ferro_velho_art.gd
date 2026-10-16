extends RefCounted

func creature_palette(character_id: String) -> Dictionary:
	var map := {
		"naro": {"base": Color("d39858"), "accent": Color("6b3d22"), "trim": Color("f4db7d"), "detail": Color("f5efe9")},
		"brumo": {"base": Color("7bd2a8"), "accent": Color("234f45"), "trim": Color("dfffe9"), "detail": Color("ecf7e8")},
		"vexa": {"base": Color("7bc7d6"), "accent": Color("3f5968"), "trim": Color("fde7a0"), "detail": Color("edf7ff")},
		"lume": {"base": Color("a55d53"), "accent": Color("4a2b21"), "trim": Color("f3d0a3"), "detail": Color("f5efe9")},
	}
	return map.get(character_id, {"base": Color("d9c39a"), "accent": Color("6e4d46"), "trim": Color("ffe195"), "detail": Color("f5efe9")})

func weapon_palette(weapon_id: String) -> Dictionary:
	var map := {
		"pulso": {"body": Color("f3d974"), "detail": Color("f2a65a"), "glow": Color("ffe7a2")},
		"lastro": {"body": Color("f59b4d"), "detail": Color("ff7143"), "glow": Color("ffd7a3")},
		"risco": {"body": Color("7de3a6"), "detail": Color("324d48"), "glow": Color("dfffe9")},
		"trinca": {"body": Color("bb8cf6"), "detail": Color("e6d4ff"), "glow": Color("f1d4ff")},
		"sonda": {"body": Color("7bd1ff"), "detail": Color("1f7cb8"), "glow": Color("dff5ff")},
	}
	return map.get(weapon_id, {"body": Color("d7c49d"), "detail": Color("e0895d"), "glow": Color("ffe195")})

func draw_creature(target: CanvasItem, character_id: String, body_color: Color, facing: int, active: bool, hp_ratio: float, flash: float) -> void:
	var palette := creature_palette(character_id)
	var primary := body_color if body_color != Color.WHITE else palette["base"]
	var shadow := primary.darkened(0.4)
	var armor := primary.lightened(0.18)
	var accent := palette["accent"]
	var trim := palette["trim"]
	var detail := palette["detail"]

	target.draw_circle(Vector2(0, 22), 18, shadow)
	var body := Rect2(-22, -18, 44, 42)
	target.draw_rect(body, armor)
	target.draw_rect(Rect2(-16, -30, 32, 12), primary)
	if character_id == "naro":
		target.draw_rect(Rect2(-24, -7, 12, 26), accent)
		target.draw_rect(Rect2(12, -7, 12, 26), accent)
		target.draw_rect(Rect2(-8, -2, 16, 20), trim)
		for sign in [-1, 1]:
			target.draw_line(Vector2(sign * 10, -12), Vector2(sign * 14, 0), accent, 5)
	elif character_id == "brumo":
		target.draw_rect(Rect2(-27, -10, 54, 12), accent)
		target.draw_rect(Rect2(-10, 12, 20, 14), trim)
		target.draw_line(Vector2(-14, -6), Vector2(-14, 8), trim, 4)
		target.draw_line(Vector2(14, -6), Vector2(14, 8), trim, 4)
		target.draw_line(Vector2(-12, -16), Vector2(12, -16), accent, 4)
	elif character_id == "vexa":
		target.draw_line(Vector2(-15, -8), Vector2(-4, -18), trim, 4)
		target.draw_line(Vector2(15, -8), Vector2(4, -18), trim, 4)
		target.draw_line(Vector2(-10, 8), Vector2(10, 8), accent, 4)
		target.draw_circle(Vector2(0, -16), 8, trim)
		target.draw_arc(Vector2(0, -16), 10, 0.5, 2.8, 12, accent, 3)
	else:
		target.draw_rect(Rect2(-18, -20, 36, 10), accent)
		target.draw_circle(Vector2(-9, -2), 6, trim)
		target.draw_circle(Vector2(9, -2), 6, trim)
		target.draw_line(Vector2(-9, 18), Vector2(9, 18), accent, 4)
		target.draw_line(Vector2(-12, 4), Vector2(0, 12), trim, 4)
		target.draw_line(Vector2(12, 4), Vector2(0, 12), trim, 4)

	target.draw_circle(Vector2(facing * 8, -14), 5, Color("0e1826"))
	var eye := Vector2(facing * 8, -10)
	target.draw_circle(eye, 2.5, detail)
	var hp_rect := Rect2(-25, -34, 50, 5)
	target.draw_rect(hp_rect, Color("2a3d52"))
	target.draw_rect(Rect2(hp_rect.position.x, hp_rect.position.y, hp_rect.size.x * hp_ratio, hp_rect.size.y), trim)
	if active and flash > 0.0:
		target.draw_circle(Vector2.ZERO, 28 + (flash * 14.0), Color(1.0, 1.0, 1.0, flash * 0.45))

func draw_weapon(target: CanvasItem, weapon_id: String, tint: Color, angle: float, facing: int, power: float) -> void:
	var palette := weapon_palette(weapon_id)
	var base := tint if tint != Color.WHITE else palette["body"]
	var body := base
	var detail := palette["detail"]
	var glow := palette["glow"]
	var dir := Vector2(cos(deg_to_rad(angle)) * facing, -sin(deg_to_rad(angle)))
	var muzzle = Vector2(0, -8) + dir * 18
	var offset := Vector2(12, 0)

	target.draw_line(Vector2(0, -4), muzzle, body, 7)
	target.draw_line(Vector2(0, -4), Vector2(0, -20), detail, 2)
	target.draw_circle(muzzle, 5.0 + power * 3.5, glow)
	if weapon_id == "trinca":
		target.draw_line(Vector2(-8, -4), Vector2(-8, -18), detail, 3)
		target.draw_line(Vector2(8, -4), Vector2(8, -18), detail, 3)
	elif weapon_id == "sonda":
		target.draw_line(Vector2(0, -16), Vector2(0, -26), glow, 2)
		target.draw_circle(Vector2(-6, -18), 3, detail)
		target.draw_circle(Vector2(6, -18), 3, detail)
	elif weapon_id == "lastro":
		target.draw_rect(Rect2(-5, -18, 10, 18), detail)
	elif weapon_id == "risco":
		target.draw_line(Vector2(-10, -8), Vector2(10, -8), glow, 3)
		target.draw_line(Vector2(0, -8), Vector2(0, -20), detail, 3)
	else:
		target.draw_rect(Rect2(-8, -18, 16, 18), detail)

func draw_projectile(target: CanvasItem, weapon_id: String, tint: Color, radius: float, power: float) -> void:
	var palette := weapon_palette(weapon_id)
	var base := tint if tint != Color.WHITE else palette["body"]
	var glow := palette["glow"]
	target.draw_circle(Vector2.ZERO, radius + 4.0, Color(base, 0.16))
	target.draw_circle(Vector2.ZERO, radius, base)
	target.draw_circle(Vector2.ZERO, maxf(2.0, radius * 0.4), glow)
	if weapon_id == "trinca":
		target.draw_arc(Vector2.ZERO, radius + 6.0, 0.0, TAU, 12, Color(glow, 0.45), 2)
	elif weapon_id == "sonda":
		target.draw_line(Vector2.ZERO, Vector2(0, -radius - 8.0), glow, 2)
	elif weapon_id == "lastro":
		target.draw_circle(Vector2.ZERO, radius + 2.0, Color(base, 0.3))
	if power > 0.75:
		target.draw_circle(Vector2.ZERO, radius + 9.0, Color(glow, 0.12))
