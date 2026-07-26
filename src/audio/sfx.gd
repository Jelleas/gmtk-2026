extends Node

## One-shot sound effects. Autoloaded, so anything can ask for a sound without
## owning a player: the boss's lines outlive the moment that triggers them, and
## the drawer's clunks have to survive the node being hidden mid-slide.

const DRAWER_OPEN := preload("res://resources/audio/drawer1.mp3")
const DRAWER_CLOSE := preload("res://resources/audio/drawer2.mp3")
const COFFEE_SLURP := preload("res://resources/audio/slurp.mp3")

## The mouse, for the things the player clicks on the computer rather than on the
## desk. The desk props have their own sounds and do not want this on top.
const MOUSE_CLICK := preload("res://resources/audio/mouse-click.mp3")
const MOUSE_CLICK_DB := -8.0
const MOUSE_CLICK_PITCH := Vector2(0.94, 1.06)

## Reaching for something the boss has put out of bounds. Played through
## DeniedFeedback, which pairs it with the flinch.
const NUH_UH := preload("res://resources/audio/nuh_uh.mp3")
const NUH_UH_DB := -11.0

## The boss thinking it over on the way up. Picked at random so a long shift
## doesn't turn into the same syllable over and over.
const BOSS_INVESTIGATE: Array[AudioStream] = [
	preload("res://resources/audio/hm.mp3"),
	preload("res://resources/audio/hmmm.mp3"),
]

## Having caught someone. Same idea, three ways of being cross about it.
const BOSS_ANGRY: Array[AudioStream] = [
	preload("res://resources/audio/brbrbr.mp3"),
	preload("res://resources/audio/wawawa.mp3"),
	preload("res://resources/audio/haha.mp3"),
]

## Enough players that overlapping sounds don't cut each other off - a drawer
## slammed under an angry boss is two at once, and the pool grows if it has to.
const INITIAL_PLAYERS := 4

var _players: Array[AudioStreamPlayer] = []
## Remembers the last pick per list so the same line never lands twice running.
var _last_choice: Dictionary = {}

func _ready() -> void:
	for i in range(INITIAL_PLAYERS):
		_add_player()

func play(stream: AudioStream, volume_db := 0.0, pitch := 1.0) -> void:
	if stream == null:
		return

	var player := _free_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()

## Plays one of a set, avoiding an immediate repeat.
func play_random(streams: Array[AudioStream], volume_db := 0.0, pitch := 1.0) -> void:
	if streams.is_empty():
		return

	var index := randi() % streams.size()
	if streams.size() > 1:
		var previous: int = _last_choice.get(streams, -1)
		while index == previous:
			index = randi() % streams.size()
	_last_choice[streams] = index

	play(streams[index], volume_db, pitch)

## The click, at the volume and with the spread of pitch it wants everywhere it
## is used, so no call site has to remember them.
func play_click() -> void:
	play(MOUSE_CLICK, MOUSE_CLICK_DB, randf_range(MOUSE_CLICK_PITCH.x, MOUSE_CLICK_PITCH.y))

func _free_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	return _add_player()

func _add_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	add_child(player)
	_players.append(player)
	return player
