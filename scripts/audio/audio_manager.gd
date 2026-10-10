class_name AudioManager
extends Node

# Plays procedural sounds through a small player pool. Missing audio device or
# volume 0 is silent, never an error. Sounds are synthesized one per frame at
# startup so no single frame hitches on slow phones.
enum Category { UI, WEAPON, IMPACT, CHARACTER, AMBIENT, MUSIC }
const POOL_SIZE: int = 10

var settings: FeelSettings = FeelSettings.new()
var players: Array[AudioStreamPlayer] = []
var next_player: int = 0
var warmup: Array = ProceduralSounds.ids()
var play_log: Array[StringName] = []

func _ready() -> void:
	for i in range(POOL_SIZE):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		players.append(voice)

func _process(_delta: float) -> void:
	if warmup.is_empty():
		return
	ProceduralSounds.stream(warmup.pop_back())

func play(sound: StringName, category: int, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var volume := settings.category_volume(category == Category.MUSIC)
	if volume <= 0.0 or not ProceduralSounds.RECIPES.has(sound) or players.is_empty():
		return
	play_log.append(sound)
	if play_log.size() > 64:
		play_log.pop_front()
	var voice := players[next_player]
	next_player = (next_player + 1) % players.size()
	voice.stream = ProceduralSounds.stream(sound)
	voice.pitch_scale = clampf(pitch, 0.5, 2.0)
	voice.volume_db = linear_to_db(volume) + volume_db
	voice.play()
