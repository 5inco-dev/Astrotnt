class_name TurnManager
extends Node

enum Phase { AIMING, PROJECTILE, TRANSITION, FINISHED }
var phase: Phase = Phase.AIMING
var active_index: int = 0
var turn_number: int = 1
var wind: int = 0
var winner: int = 0
var random := MatchRandom.new(CombatConfig.WIND_SEED)

func reset(seed_value: int = CombatConfig.WIND_SEED) -> void:
	random.reseed(seed_value)
	active_index = 0
	turn_number = 1
	winner = 0
	phase = Phase.AIMING
	wind = WindSystem.roll(random)

func start_shot() -> bool:
	if phase != Phase.AIMING:
		return false
	phase = Phase.PROJECTILE
	return true

func next_turn() -> void:
	if phase != Phase.TRANSITION:
		return
	active_index = 1 - active_index
	turn_number += 1
	wind = WindSystem.roll(random)
	phase = Phase.AIMING

func finish_match(player_number: int) -> void:
	winner = player_number
	phase = Phase.FINISHED
