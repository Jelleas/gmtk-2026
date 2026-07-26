class_name LoopSound
extends Node

## A sound that runs for as long as something keeps happening, rather than once
## per event. Typing is the case it was written for: a keystroke is too short to
## hang a clip off, but a burst of them wants a continuous clatter that trails
## off when the player stops.
##
## Call bump() on every event. The first one starts the loop; the rest just push
## the silence back. Once they stop coming, the sound fades rather than cutting.

## How long after the last bump() the sound starts going away.
@export var idle_seconds := 0.25
@export var fade_seconds := 0.3
@export var volume_db := -6.0
## Re-rolled on every fresh start so a long stretch of typing does not sound like
## the same three seconds on repeat.
@export var pitch_range := Vector2(0.94, 1.08)
## Where the fade lands. Low enough to be gone before the player is stopped.
@export var silent_db := -40.0

var player: AudioStreamPlayer
var idle_timer: Timer
var fade_tween: Tween

func setup(stream: AudioStream) -> void:
	player = AudioStreamPlayer.new()
	# Duplicated before being made to loop: the import is shared with anything else
	# that preloads the same file, and looping is this node's business alone.
	var looping := stream.duplicate()
	if "loop" in looping:
		looping.loop = true
	player.stream = looping
	add_child(player)

	idle_timer = Timer.new()
	idle_timer.one_shot = true
	idle_timer.wait_time = idle_seconds
	idle_timer.timeout.connect(fade_out)
	add_child(idle_timer)

## Another event happened: start the sound if it is not going, and either way put
## off the fade.
func bump() -> void:
	if player == null:
		return

	if fade_tween:
		fade_tween.kill()
		fade_tween = null

	player.volume_db = volume_db
	if not player.playing:
		player.pitch_scale = randf_range(pitch_range.x, pitch_range.y)
		player.play()
	idle_timer.start(idle_seconds)

func fade_out() -> void:
	if player == null or not player.playing:
		return

	idle_timer.stop()
	fade_tween = create_tween()
	fade_tween.tween_property(player, "volume_db", silent_db, fade_seconds)
	fade_tween.tween_callback(player.stop)

## Cuts the sound dead, for when the moment it belonged to is over rather than
## merely quiet.
func stop() -> void:
	if player == null:
		return

	if fade_tween:
		fade_tween.kill()
		fade_tween = null
	idle_timer.stop()
	player.stop()
