class_name LookBusyTask
extends Task

## Teaches the boss loop: while the boss is up, its watch fills, and whatever is
## running when it runs out is what gets punished. Completed the moment the desk
## goes clean under that watch - the player does not have to wait the boss out,
## stopping the spinner is the lesson.

var watching := false
var survived := false
var activity_states: Dictionary[StringName, bool] = {}

func _init() -> void:
	super._init("Look busy", "Look busy, right click the spinner before the boss notices", null)
	EventBus.boss_watch_started.connect(_on_boss_watch_started)
	EventBus.boss_watch_ended.connect(_on_boss_watch_ended)
	EventBus.activity_started.connect(_on_activity_started)
	EventBus.activity_ended.connect(_on_activity_ended)

func start_task() -> void:
	pass

func check_completed() -> bool:
	return survived

func _on_boss_watch_started() -> void:
	watching = true
	_check_survived()

func _on_boss_watch_ended() -> void:
	watching = false

func _check_survived() -> void:
	if survived or not watching or _has_active_activities():
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
	_check_survived()
