class_name GameStats
extends RefCounted

## Everything worth saying about one run of the day, gathered by [StatTracker]
## and read back by whatever wants to show it off.
##
## The time figures all come from the same per-frame integral the clock runs on,
## so they stay in step with the clock the player was watching.

## Wall-clock seconds between the day starting and the day ending.
var real_seconds := 0.0
## The same seconds, each weighted by the multiplier that was running: how long
## the day would have taken at a standstill. See real_seconds_saved().
var multiplier_seconds := 0.0
## Of real_seconds, how many were spent with the clock frozen for punishment.
var punished_seconds := 0.0
## The highest stacked multiplier the player ever had going at once.
var peak_multiplier := 1.0

## Per activity id: how often it was started, and how long it ran.
var activations: Dictionary[StringName, int] = {}
var active_seconds: Dictionary[StringName, float] = {}

var fidget_clicks := 0
var swipes_left := 0
var swipes_right := 0
var video_coins := 0
var video_hits := 0

## Times the boss came up for a look, and how many of those looks found
## something. The rest were survived.
var boss_peeks := 0
var times_caught := 0
var punishment_tasks_completed := 0
var tutorial_beats_completed := 0

## Only true once the clock has actually run out - a run that was quit or is
## still going has stats, but did not finish.
var finished := false

## How much real time the distractions bought. The clock spends game time at
## delta * 60 * multiplier * negative_multiplier(), and that last term depends
## only on the time left, which a distraction-free run passes through all the
## same - so every game second simply costs `multiplier` times more real seconds
## without them. The day without distractions is multiplier_seconds long.
func real_seconds_saved() -> float:
	return multiplier_seconds - real_seconds

## Time-weighted over the whole day, idling included: idle frames count as 1.0
## and drag it down, which is the point of the number.
func average_multiplier() -> float:
	if real_seconds <= 0.0:
		return 1.0
	return multiplier_seconds / real_seconds

func peeks_survived() -> int:
	return boss_peeks - times_caught

func total_activations() -> int:
	var total := 0
	for count in activations.values():
		total += count
	return total

func get_activations(source_id: StringName) -> int:
	return activations.get(source_id, 0)

func get_active_seconds(source_id: StringName) -> float:
	return active_seconds.get(source_id, 0.0)

func total_swipes() -> int:
	return swipes_left + swipes_right

## M:SS, for durations that are minutes rather than a working day. The clock has
## its own HH:MM:SS formatting for the in-fiction time.
static func format_duration(seconds: float) -> String:
	var total := int(seconds)
	return "%d:%02d" % [total / 60, total % 60]
