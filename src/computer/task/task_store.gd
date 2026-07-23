class_name TaskStore

var TASK_TYPES := [
	FillRowTask,
	EmptySpreadsheetTask,
	FillColumnTask,
]

var spreadsheet: Spreadsheet
var active_tasks: Array[Task] = []

func _init(p_spreadsheet: Spreadsheet) -> void:
	spreadsheet = p_spreadsheet
	EventBus.task_completed.connect(on_task_completed)

func assign_new_task() -> Task:
	var available_types := TASK_TYPES.filter(func(task_type: Script) -> bool:
		return not _has_active_task_of_type(task_type)
	)
	if available_types.is_empty():
		return null

	var task_type: Script = available_types[randi() % available_types.size()]
	var task: Task = task_type.new(spreadsheet)
	active_tasks.append(task)

	EventBus.task_added.emit(task)
	return task

func _has_active_task_of_type(task_type: Script) -> bool:
	for task in active_tasks:
		if task.get_script() == task_type:
			return true
	return false

func on_task_completed(task: Task) -> void:
	active_tasks.erase(task)
