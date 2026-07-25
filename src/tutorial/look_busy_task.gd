class_name LookBusyTask
extends Task

## Teaches the boss loop: while the boss is up, its watch fills, and whatever is
## running when it runs out is what gets punished. Completed by being clean deep
## into that window - the player has to stop the distraction before the boss
## finishes looking.

## How far the watch has to have filled before being clean counts as surviving.
const WATCH_THRESHOLD := 0.85

var survived := false
var activity_states: Dictionary[StringName, bool] = {}

func _init() -> void:
	super._init("Look busy", "Look busy before the boss notices", null)
	EventBus.boss_watch_progress.connect(_on_boss_watch_progress)
	EventBus.activity_started.connect(_on_activity_started)
	EventBus.activity_ended.connect(_on_activity_ended)

func start_task() -> void:
	pass

func check_completed() -> bool:
	return survived

func _on_boss_watch_progress(progress: float) -> void:
	if survived or progress < WATCH_THRESHOLD or _has_active_activities():
		return
	survived = true
	notify_changed()

func _has_active_activities() -> bool:
	for is_running in activity_states.values():
		if is_running:
			return true
	return false

func _on_activity_started(source_id: StringName, _multiplier: float) -> void:
	activity_states[source_id] = true

func _on_activity_ended(source_id: StringName) -> void:
	activity_states[source_id] = false
