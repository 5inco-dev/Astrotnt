class_name FloatingText
extends Node2D

# Short-lived world-space label (damage numbers, shot feedback). Moved in
# _process, so it opts out of physics interpolation.
var text: String = ""
var tint: Color = Color.WHITE
var font_size: int = 28
var life: float = 1.2
var age: float = 0.0

func _init() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	z_index = 20

func _process(delta: float) -> void:
	age += delta
	position.y -= 38.0 * delta
	modulate.a = clampf((life - age) / 0.4, 0.0, 1.0)
	if age >= life:
		queue_free()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := Vector2(-width * 0.5, 0.0)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color(0.03, 0.06, 0.1, 0.9))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)
