class_name CombatInput
extends Node

# Physical input sources are merged before simulation consumes a command.
# Each finger/key has its own identity; releasing one cannot release another.
var sources: Dictionary = {}
var fire_pressed: bool = false
var fire_released: bool = false
var canceled: bool = false

func set_source(source: String, action: String, pressed: bool) -> void:
	var was_firing := is_held("fire")
	if pressed:
		sources[source] = action
	else:
		sources.erase(source)
	var firing := is_held("fire")
	fire_pressed = fire_pressed or (firing and not was_firing)
	fire_released = fire_released or (was_firing and not firing)

func is_held(action: String) -> bool:
	return sources.values().has(action)

func consume() -> Dictionary:
	var command := {
		"move": float(is_held("right")) - float(is_held("left")),
		"aim": float(is_held("up")) - float(is_held("down")),
		"fire_pressed": fire_pressed,
		"fire_released": fire_released,
		"cancel": canceled,
	}
	fire_pressed = false
	fire_released = false
	canceled = false
	return command

func clear() -> void:
	sources.clear()
	fire_pressed = false
	fire_released = false
	canceled = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		clear()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		var action: String = {
			KEY_A: "left", KEY_LEFT: "left", KEY_D: "right", KEY_RIGHT: "right",
			KEY_W: "up", KEY_UP: "up", KEY_S: "down", KEY_DOWN: "down",
			KEY_SPACE: "fire",
		}.get(event.physical_keycode, "")
		if not action.is_empty():
			set_source("key_%s" % event.physical_keycode, action, event.pressed)
