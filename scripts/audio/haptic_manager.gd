class_name HapticManager
extends RefCounted

# Short vibration pulses. Silent no-op where the device has none (desktop, or an
# Android editor run without the VIBRATE permission). Never continuous.
const SHOT_MS: int = 15
const IMPACT_MS: int = 30
const BIG_IMPACT_MS: int = 55
const MIN_GAP_MS: int = 80

var enabled: bool = true
var supported: bool = OS.has_feature("mobile")
var requests: Array[int] = []
var last_ms: int = -1000000

func pulse(duration_ms: int, now_ms: int = Time.get_ticks_msec()) -> void:
	if not enabled or now_ms - last_ms < MIN_GAP_MS:
		return
	last_ms = now_ms
	requests.append(duration_ms)
	if requests.size() > 32:
		requests.pop_front()
	if supported:
		Input.vibrate_handheld(duration_ms)
