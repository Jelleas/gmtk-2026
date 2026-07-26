class_name DeniedFeedback
extends RefCounted

## The game saying no. While the boss is watching, reaching for a distraction does
## nothing whatsoever, which reads as a dead click rather than as a rule - so the
## thing the player reached for flinches and the game tuts at them.

## One flinch, out and back with the swing decaying. Short enough to be a twitch
## rather than an animation the player has to sit through before trying again.
const SHAKE_PIXELS := 7.0
const SHAKE_SECONDS := 0.28
const SHAKE_SWINGS: Array[float] = [1.0, -0.7, 0.45, -0.2, 0.0]

## Mashing a blocked prop should tut once, not stutter. Shared across every prop,
## so hammering two of them in turn does not double up either.
const REPEAT_SECONDS := 0.5
static var _last_sound_msec := -100000

## Set on a node for as long as it is mid-flinch, so a second denial cannot start
## a competing tween from an already-displaced position.
const _SHAKING_META := &"denied_shaking"


## The whole no: the noise, and a flinch from whatever was reached for.
static func deny(target: Node = null) -> void:
	_tut()
	shake(target)


static func _tut() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_sound_msec < int(REPEAT_SECONDS * 1000.0):
		return

	_last_sound_msec = now
	Sfx.play(Sfx.UH_UH, Sfx.UH_UH_DB)


## Flinches a node in place. The resting position is read on the way in and put
## back on the way out, so an interrupted flinch cannot leave a prop parked off
## its mark. Written through set()/tween_property rather than target.position so
## it takes Node2Ds and Controls alike.
static func shake(target: Node) -> void:
	if target == null or not target.is_inside_tree():
		return
	if target.get_meta(_SHAKING_META, false):
		return

	var rest = target.get(&"position")
	if rest == null:
		return

	target.set_meta(_SHAKING_META, true)
	var step := SHAKE_SECONDS / SHAKE_SWINGS.size()

	var tween := target.create_tween()
	for swing in SHAKE_SWINGS:
		tween.tween_property(target, "position", rest + Vector2(SHAKE_PIXELS * swing, 0.0), step) \
			.set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void:
		target.set(&"position", rest)
		target.set_meta(_SHAKING_META, false)
	)
