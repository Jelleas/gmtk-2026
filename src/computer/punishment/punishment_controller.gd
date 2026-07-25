class_name PunishmentController
extends Node

## Runs the punishment the boss hands out: one extra task per activity it
## spotted, listed on its own post-it and worked through one at a time. The
## punishment is only over once every task is done and every activity has
## stopped - only then does the boss get the signal to leave.

const STOP_DISTRACTIONS_MESSAGE := "Stop all distractions before continuing"

## All three are handed over by office.gd, which owns the task store.
var task_store: TaskStore
var spreadsheet: Spreadsheet
var post_it_stack: PostItStack

var tasks: Array[Task] = []
var current_index := 0
var activity_states: Dictionary[StringName, bool] = {}

func _ready() -> void:
	EventBus.punishment_started.connect(_on_punishment_started)
	EventBus.activity_started.connect(_on_activity_started)
	EventBus.activity_ended.connect(_on_activity_ended)

func setup(p_task_store: TaskStore, p_spreadsheet: Spreadsheet, p_post_it_stack: PostItStack) -> void:
	task_store = p_task_store
	spreadsheet = p_spreadsheet
	post_it_stack = p_post_it_stack

func is_punishing() -> bool:
	return not tasks.is_empty()

func _on_punishment_started(activity_count: int) -> void:
	if is_punishing():
		return

	tasks = task_store.create_punishment_tasks(activity_count)
	current_index = 0

	var descriptions: Array[String] = []
	for task in tasks:
		descriptions.append(task.description)
	post_it_stack.start_punishment(descriptions)

	_start_current()

func _start_current() -> void:
	var task := tasks[current_index]
	task.changed.connect(_on_current_task_changed)
	task.start_task()
	spreadsheet.set_status_message(task.description)

func _on_current_task_changed() -> void:
	var task := tasks[current_index]
	if not task.check_completed():
		return

	task.changed.disconnect(_on_current_task_changed)
	post_it_stack.advance_punishment(current_index)
	current_index += 1

	if current_index < tasks.size():
		_start_current()
	else:
		_try_finish()

## The boss does not accept the work while a distraction is still running.
func _try_finish() -> void:
	if _has_active_activities():
		spreadsheet.set_status_message(STOP_DISTRACTIONS_MESSAGE)
		return

	tasks.clear()
	current_index = 0
	post_it_stack.end_punishment()
	EventBus.punishment_ended.emit()

func _has_active_activities() -> bool:
	for is_running in activity_states.values():
		if is_running:
			return true
	return false

func _on_activity_started(source_id: StringName, _multiplier: float) -> void:
	activity_states[source_id] = true

func _on_activity_ended(source_id: StringName) -> void:
	activity_states[source_id] = false
	if is_punishing() and current_index >= tasks.size():
		_try_finish()
