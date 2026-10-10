class_name EquipmentProfile
extends Resource

@export var id: String
@export var title: String
@export_enum("head", "body", "accessory") var slot: String = "head"
@export var modifiers: Dictionary = {}
@export var tint: Color = Color.WHITE
@export_range(0, 2) var shape: int = 0

func valid() -> bool:
	return (not id.is_empty() and not title.is_empty() and slot in ["head", "body", "accessory"]
		and StatRules.valid(modifiers, true) and shape >= 0 and shape <= 2
		and tint.is_equal_approx(tint.clamp()))
