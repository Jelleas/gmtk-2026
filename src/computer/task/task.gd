@abstract class_name Task

var title: String
var description: String
var target: Node

func _init(p_title: String, p_description: String, p_target: Node) -> void:
	title = p_title
	description = p_description
	target = p_target

@abstract func check_completed() -> bool
