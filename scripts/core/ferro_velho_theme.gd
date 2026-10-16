class_name FerroVelhoTheme
extends RefCounted

const BACKDROP := Color("0b1113")
const PANEL := Color("172327")
const PANEL_STRONG := Color("22373a")
const METAL := Color("a9b7be")
const SCRAP := Color("d39858")
const RUST := Color("b75f3d")
const PLASTIC := Color("7bd2a8")
const WARNING := Color("ffe195")
const DANGER := Color("ff7d5a")
const SHADOW := Color("050a0d")
const CRT := Color("b5f0d3")
const MIRE := Color("f2c14e")

static func menu_background() -> Color:
	return BACKDROP

static func panel_style() -> Dictionary:
	return {
		"bg": PANEL,
		"border": PANEL_STRONG,
		"warning": WARNING,
		"scrap": SCRAP,
		"rust": RUST,
		"glass": PLASTIC,
	}

static func creature_palette(name: String) -> Dictionary:
	var palettes := {
		"latao": {"base": Color("c79853"), "accent": Color("d15d2d"), "trim": Color("f4db7d"), "face": Color("f2f0d8")},
		"zip": {"base": Color("7bc7d6"), "accent": Color("d0f1ff"), "trim": Color("f6d28c"), "face": Color("e6f2f8")},
		"tubo": {"base": Color("7aa87a"), "accent": Color("8de0bb"), "trim": Color("d9f6d7"), "face": Color("ecf7e8")},
		"trapo": {"base": Color("a55d53"), "accent": Color("f2bb7d"), "trim": Color("d6d2c8"), "face": Color("f5efe9")},
	}
	return palettes.get(name, {"base": Color("d8d3c0"), "accent": Color("d16b42"), "trim": Color("ffe195"), "face": Color("f5efe9")})
}

static func weapon_palette(name: String) -> Dictionary:
	var palettes := {
		"pulso": {"body": Color("f3d974"), "detail": Color("f2a65a"), "glow": Color("ffe7a2")},
		"lastro": {"body": Color("f59b4d"), "detail": Color("ff7143"), "glow": Color("ffd7a3")},
		"risco": {"body": Color("7de3a6"), "detail": Color("324d48"), "glow": Color("dfffe9")},
		"trinca": {"body": Color("bb8cf6"), "detail": Color("e6d4ff"), "glow": Color("f1d4ff")},
		"sonda": {"body": Color("7bd1ff"), "detail": Color("1f7cb8"), "glow": Color("dff5ff")},
	}
	return palettes.get(name, {"body": Color("d7c49d"), "detail": Color("e0895d"), "glow": Color("ffe195")})
}

static func map_palette(name: String) -> Dictionary:
	var palettes := {
		"aterro_zero": {"ground": Color("4d493d"), "platform": Color("7b5e3e"), "danger": Color("b36d3e"), "mist": Color("d9b576")},
		"fabrica_fim": {"ground": Color("3d4646"), "platform": Color("5d6d70"), "danger": Color("d9a15f"), "mist": Color("e9d9b7")},
		"cidade_descartada": {"ground": Color("443c37"), "platform": Color("8f6952"), "danger": Color("d28d68"), "mist": Color("f1d2a5")},
		"pantano_quimico": {"ground": Color("2e3d35"), "platform": Color("536d58"), "danger": Color("86b883"), "mist": Color("d7f0c4")},
	}
	return palettes.get(name, {"ground": Color("5d5c56"), "platform": Color("826d5d"), "danger": Color("d18f52"), "mist": Color("f3d08e")})
}
