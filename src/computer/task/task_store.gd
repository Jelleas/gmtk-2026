class_name TaskStore

var TASK_TYPES := [
	FillRowTask,
	EmptySpreadsheetTask,
]

var spreadsheet: Spreadsheet
var active_tasks: Array[Task] = []

func _init(p_spreadsheet: Spreadsheet) -> void:
	spreadsheet = p_spreadsheet
	EventBus.task_completed.connect(on_task_completed)

func assign_new_task() -> Task:
	var task_type: Script = TASK_TYPES[randi() % TASK_TYPES.size()]
	var task: Task = task_type.new(spreadsheet)
	active_tasks.append(task)
		
	EventBus.task_added.emit(task)
	return task

func on_task_completed(task: Task) -> void:
	active_tasks.erase(task)
