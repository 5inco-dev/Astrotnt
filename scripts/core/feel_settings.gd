class_name FeelSettings
extends RefCounted

# Player-facing feedback options. Held by the match, never global; a future
# SaveManager persists it. Volumes are linear 0..1.
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 1.0
var haptics_enabled: bool = true
var shake_scale: float = 1.0
var vfx_enabled: bool = true

func category_volume(is_music: bool) -> float:
	var base := music_volume if is_music else sfx_volume
	return clampf(master_volume, 0.0, 1.0) * clampf(base, 0.0, 1.0)
