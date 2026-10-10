class_name ProceduralSounds
extends RefCounted

# Original arcade sounds synthesized from math (no external assets). Fixed noise
# seed, so every build produces identical samples. Streams are cached.
const RATE: int = 22050
static var cache: Dictionary = {}

const RECIPES: Dictionary = {
	&"click": [0.06, 900.0, 700.0, 0.0, 30.0, 0.0],
	&"shot": [0.22, 520.0, 110.0, 0.45, 12.0, 0.25],
	&"boom_small": [0.45, 120.0, 45.0, 0.55, 7.0, 0.5],
	&"boom_big": [0.7, 85.0, 30.0, 0.7, 4.5, 0.6],
	&"debris": [0.25, 0.0, 0.0, 1.0, 9.0, 0.0],
	&"damage": [0.14, 260.0, 140.0, 0.15, 18.0, 0.0],
}

static func ids() -> Array:
	return RECIPES.keys()

static func stream(id: StringName) -> AudioStreamWAV:
	if not cache.has(id):
		cache[id] = build(id)
	return cache[id]

# recipe: [duration, start_hz, end_hz, noise_mix, decay, smoothing]
static func build(id: StringName) -> AudioStreamWAV:
	var recipe: Array = RECIPES[id]
	var count := int(float(recipe[0]) * RATE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	var smooth := 0.0
	for i in range(count):
		var t := float(i) / RATE
		var progress := float(i) / maxf(1.0, float(count))
		phase += TAU * lerpf(float(recipe[1]), float(recipe[2]), progress) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		var lowpass := float(recipe[5])
		if lowpass > 0.0:
			smooth = lerpf(smooth, noise, 1.0 - lowpass)
			noise = smooth * 2.5
		var sample := sin(phase) * (1.0 - float(recipe[3])) + noise * float(recipe[3])
		var attack := minf(1.0, t / 0.002)
		sample *= exp(-float(recipe[4]) * t) * attack * 0.8
		bytes.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav
