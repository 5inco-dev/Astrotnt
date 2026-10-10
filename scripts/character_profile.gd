class_name CharacterProfile
extends Resource

@export var id: String
@export var title: String
@export var description: String
@export var tint: Color = Color.WHITE
@export var stats: Dictionary = StatRules.BASE.duplicate()
@export var gravity: float = 1000.0
@export_range(0, 3) var emblem: int = 0

func valid() -> bool:
	return (not id.is_empty() and not title.is_empty() and StatRules.valid(stats)
		and is_finite(gravity) and gravity >= 900 and gravity <= 1100
		and tint.is_equal_approx(tint.clamp()) and emblem >= 0 and emblem <= 3)
