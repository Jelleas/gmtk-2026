class_name StartActivityTask
extends Task

## Teaches a distraction by asking the player to start it. Completed the moment
## the thing announces itself on the bus, so it does not care how it was reached.

var source_id: StringName
var started := false

func _init(p_source_id: StringName, p_title: String, p_description: String) -> void:
	super._init(p_title, p_description, null)
	source_id = p_source_id
	EventBus.activity_started.connect(_on_activity_started)

func start_task() -> void:
	pass

func check_completed() -> bool:
	return started

func _on_activity_started(id: StringName, _bonus: float) -> void:
	if id != source_id:
		return
	started = true
	notify_changed()
