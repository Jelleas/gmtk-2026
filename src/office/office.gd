extends Node2D

const TARGET_TASK_COUNT := 2

@export var task_refill_delay := 2.0

var task_store: TaskStore
var refill_timer: Timer

func _ready():
	task_store = TaskStore.new($Screen/Computer.spreadsheet)
	EventBus.task_completed.connect(_on_task_completed)
	EventBus.punishment_ended.connect(_on_punishment_ended)
	$FidgetSpinner.started.connect($OfficeView.play_fidget_spin)
	$FidgetSpinner.stopped.connect($OfficeView.stop_fidget_spin)

	refill_timer = Timer.new()
	refill_timer.one_shot = true
	refill_timer.timeout.connect(_refill_tasks)
	add_child(refill_timer)

	_refill_tasks()

func _on_task_completed(_task: Task) -> void:
	refill_timer.start(task_refill_delay)

func _on_punishment_ended() -> void:
	for task in task_store.active_tasks:
		if task is SpreadsheetTask:
			task.get_spreadsheet().set_status_message("")
			task.start_task()
			return

func _refill_tasks() -> void:
	while task_store.active_tasks.size() < TARGET_TASK_COUNT:
		if task_store.assign_new_task() == null:
			break
