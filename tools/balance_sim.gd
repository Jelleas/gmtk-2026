## Measures how long a round actually takes at a given multiplier, by stepping the
## real clock's own formula. Run it after touching anything in clock.gd's balance
## constants - the drag curve integrates to a round length in a way that is not
## obvious by reading it.
##
##     godot --headless --script tools/balance_sim.gd
##
## Targets: idle 30 min, 6x 5 min, 15x 2 min.
extends SceneTree

const STEP := 1.0 / 60.0

## _initialize(), not _init(): quit() is only honoured once the main loop is up.
func _initialize() -> void:
	var clock: Node = load("res://src/clock/clock.gd").new()
	var day: float = clock.time

	print("idle day target: %s" % _format(clock.IDLE_DAY_SECONDS))
	print("")
	print(" multiplier | round length | share in last hour")
	print("------------+--------------+-------------------")
	for multiplier in [1.0, 3.0, 6.0, 9.0, 15.0, 21.0]:
		var result := _simulate(clock, day, multiplier)
		print("%10.1fx | %12s | %16.0f%%" % [
			multiplier,
			_format(result["seconds"]),
			result["last_hour_seconds"] / result["seconds"] * 100.0,
		])

	clock.free()
	quit()

## Runs a whole day at a fixed multiplier and reports the real seconds it took,
## plus how many of those were spent inside the final in-game hour.
func _simulate(clock: Node, day: float, multiplier: float) -> Dictionary:
	clock.time = day
	var seconds := 0.0
	var last_hour_seconds := 0.0
	while clock.time > 0.0:
		clock.time -= STEP * 60.0 * multiplier * clock.negative_multiplier()
		seconds += STEP
		if clock.time <= clock.LAST_HOUR:
			last_hour_seconds += STEP
	return {"seconds": seconds, "last_hour_seconds": last_hour_seconds}

func _format(seconds: float) -> String:
	return "%d:%04.1f" % [int(seconds) / 60, fmod(seconds, 60.0)]
