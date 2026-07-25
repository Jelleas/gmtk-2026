class_name SurviveDayTask
extends Task

## The last beat, and the whole game in one line: the clock only moves when the
## player is not working, so the day has to be wasted to be finished.

var day_over := false

func _init() -> void:
	super._init(
		"Reach the end of the day",
		"Distract yourself to reach the end of the day",
		null,
	)
	EventBus.day_ended.connect(_on_day_ended)

func start_task() -> void:
	pass

func check_completed() -> bool:
	return day_over

func _on_day_ended(_realtime: float) -> void:
	day_over = true
	notify_changed()
