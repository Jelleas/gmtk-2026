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
		if _has_active_task_of_type(task_type):
			return false
		if _is_spreadsheet_task_type(task_type) and _has_active_spreadsheet_task():
			return false
		return true
	)
	if available_types.is_empty():
		return null

	var task_type: Script = available_types[randi() % available_types.size()]
	var task: Task = task_type.new(spreadsheet)
	task.start_task()
	active_tasks.append(task)

	EventBus.task_added.emit(task)
	return task

func _has_active_task_of_type(task_type: Script) -> bool:
	for task in active_tasks:
		if task.get_script() == task_type:
			return true
	return false

func _has_active_spreadsheet_task() -> bool:
	for task in active_tasks:
		if task is SpreadsheetTask:
			return true
	return false

func _is_spreadsheet_task_type(task_type: Script) -> bool:
	var current: Script = task_type
	while current:
		if current == SpreadsheetTask:
			return true
		current = current.get_base_script()
	return false

func on_task_completed(task: Task) -> void:
	active_tasks.erase(task)
