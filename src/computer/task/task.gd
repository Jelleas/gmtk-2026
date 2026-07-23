@abstract class_name Task

signal changed

var title: String
var description: String
var target: Node

func _init(p_title: String, p_description: String, p_target: Node) -> void:
	title = p_title
	description = p_description
	target = p_target

# Subclasses call this whenever something relevant to completion happens.
# It only notifies listeners (e.g. TaskStore, or a wrapping Task) - it does
# not decide completion itself, so wrapping tasks can add their own rules
# before reporting completion.
func notify_changed() -> void:
	changed.emit()

@abstract func start_task() -> void
@abstract func check_completed() -> bool
