class_name LookBusyTask
extends Task

## Teaches the reflex the whole game runs on: put the distraction away. Completed
## the moment the desk is clean, with no reference to the boss - the boss is the
## deadline here, not the condition. TutorialController owns the timing: it is on
## its way up either way, and beating it there only buys a shorter look.

var survived := false
var activity_states: Dictionary[StringName, bool] = {}

func _init() -> void:
	super._init("Look busy", "Look busy, right click the spinner before the boss notices", null)
	EventBus.activity_started.connect(_on_activity_started)
	EventBus.activity_ended.connect(_on_activity_ended)

func start_task() -> void:
	pass

func check_completed() -> bool:
	return survived

func _has_active_activities() -> bool:
	for is_running in activity_states.values():
		if is_running:
			return true
	return false

func _on_activity_started(source_id: StringName, _bonus: float) -> void:
	activity_states[source_id] = true

func _on_activity_ended(source_id: StringName) -> void:
	activity_states[source_id] = false
	if survived or _has_active_activities():
		return
	survived = true
	notify_changed()
