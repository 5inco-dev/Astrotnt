class_name MatchRandom
extends RefCounted

# Single source of match randomness. Same seed => same sequence, which is the
# base for replay, tests and a future authoritative server.
var seed_value: int = 0
var _rng := RandomNumberGenerator.new()

func _init(initial_seed: int = 0) -> void:
	reseed(initial_seed)

func reseed(value: int) -> void:
	seed_value = value
	_rng.seed = value

func int_range(low: int, high: int) -> int:
	return _rng.randi_range(low, high)

func float_range(low: float, high: float) -> float:
	return _rng.randf_range(low, high)

# Only place allowed to consume non-reproducible entropy (choosing a seed).
static func fresh_seed() -> int:
	return randi() & 0x7fffffff
