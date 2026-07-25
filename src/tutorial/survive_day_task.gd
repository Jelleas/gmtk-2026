class_name SurviveDayTask
extends Task

## The last beat, and the whole game in one line: the clock only moves when the
## player is not working, so the day has to be wasted to be finished.

## The clock crawls through the last hour, so the note stops asking and starts
## encouraging - the player has not stalled, the day has.
const LAST_HOUR_TEXT := "The last hour drags, keep at it!"

var day_over := false
var in_last_hour := false

func _init() -> void:
	super._init(
		"Reach the end of the day",
		"Distract yourself to reach the end of the day",
		null,
	)
	EventBus.last_hour_started.connect(_on_last_hour_started)
	EventBus.day_ended.connect(_on_day_ended)

func start_task() -> void:
	pass

func check_completed() -> bool:
	return day_over

## What the note reads, which changes when the day enters its last hour.
func progress_description() -> String:
	return LAST_HOUR_TEXT if in_last_hour else description

func _on_last_hour_started() -> void:
	in_last_hour = true
	notify_changed()

func _on_day_ended(_realtime: float) -> void:
	day_over = true
	notify_changed()
