class_name StopDistractionsTask
extends Task

## A prerequisite the boss hands out before the punishment work: every
## distraction has to be off. The task is created while activities are already
## running, so the caller seeds it with the activities it knows about.

var activity_states: Dictionary[StringName, bool] = {}

func _init(target_node: Node, running_activities: Dictionary) -> void:
	super._init("Stop all distractions", "Stop all distractions", target_node)
	# Copied, not shared: the caller keeps tracking activities of its own.
	for source_id: StringName in running_activities:
		activity_states[source_id] = running_activities[source_id]
	EventBus.activity_started.connect(_on_activity_started)
	EventBus.activity_ended.connect(_on_activity_ended)

func start_task() -> void:
	pass

func check_completed() -> bool:
	for is_running in activity_states.values():
		if is_running:
			return false
	return true

func _on_activity_started(source_id: StringName, _multiplier: float) -> void:
	activity_states[source_id] = true
	notify_changed()

func _on_activity_ended(source_id: StringName) -> void:
	activity_states[source_id] = false
	notify_changed()
