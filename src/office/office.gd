extends Node2D

const TARGET_TASK_COUNT := 2

@export var task_refill_delay := 2.0

var task_store: TaskStore
var refill_timer: Timer
var is_punished := false

func _ready():
	var spreadsheet: Spreadsheet = $Screen/Computer.spreadsheet
	task_store = TaskStore.new(spreadsheet)
	$Punishment.setup(task_store, spreadsheet, $PostItStack)
	EventBus.task_completed.connect(_on_task_completed)
	EventBus.punishment_started.connect(_on_punishment_started)
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

func _on_punishment_started(_activity_count: int) -> void:
	is_punished = true

func _on_punishment_ended() -> void:
	is_punished = false
	# The punishment took over the spreadsheet, so hand the regular work back.
	for task in task_store.active_tasks:
		if task is SpreadsheetTask:
			task.get_spreadsheet().set_status_message("")
			task.start_task()
			break
	refill_timer.start(task_refill_delay)

func _refill_tasks() -> void:
	# Handing out regular work mid-punishment would start another spreadsheet
	# task and wipe the sheet the punishment is running on.
	if is_punished:
		return

	while task_store.active_tasks.size() < TARGET_TASK_COUNT:
		if task_store.assign_new_task() == null:
			break
