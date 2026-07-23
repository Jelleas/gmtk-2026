class_name PunishmentTask
extends Task

var wrapped_task: Task
var activity_states: Dictionary[StringName, bool] = {}

func _init(task: Task) -> void:
	wrapped_task = task
	super._init(task.title, task.description, task.target)
	wrapped_task.changed.connect(notify_changed)
	EventBus.activity_started.connect(_on_activity_started)
	EventBus.activity_ended.connect(_on_activity_ended)

func start_task() -> void:
	wrapped_task.start_task()

func check_completed() -> bool:
	return wrapped_task.check_completed() and not has_active_activities()

func has_active_activities() -> bool:
	for is_running in activity_states.values():
		if is_running:
			return true
	return false

func _on_activity_started(source_id: StringName, _multiplier: float) -> void:
	activity_states[source_id] = true
	notify_changed()

func _on_activity_ended(source_id: StringName) -> void:
	activity_states[source_id] = false
	notify_changed()
