class_name PunishmentController
extends Node

## Runs the punishment the boss hands out: one extra task per activity it
## spotted, listed on its own post-it and worked through one at a time. The
## punishment is only over once every task is done and every activity has
## stopped - only then does the boss get the signal to leave.
##
## The boss does not let the player start on the work straight away: while a
## distraction is still running or the spreadsheet is out of view, a prep note on
## top lists those prerequisites. The punishment work starts when they are met.

const STOP_DISTRACTIONS_MESSAGE := "Stop all distractions before continuing"
const PREP_MESSAGE := "Get back to work"

## IDLE: no punishment. PREP: sorting out the prerequisites. WORK: doing the
## punishment tasks.
enum Phase { IDLE, PREP, WORK }

## All three are handed over by office.gd, which owns the task store.
var task_store: TaskStore
var spreadsheet: Spreadsheet
var post_it_stack: PostItStack

var phase := Phase.IDLE
var tasks: Array[Task] = []
var current_index := 0
var prep_tasks: Array[Task] = []
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
	return phase != Phase.IDLE

func _on_punishment_started(activity_count: int) -> void:
	if is_punishing():
		return

	tasks = task_store.create_punishment_tasks(activity_count)
	current_index = 0

	var descriptions: Array[String] = []
	for task in tasks:
		descriptions.append(task.description)
	post_it_stack.start_punishment(descriptions)

	if _has_active_activities() or not spreadsheet.is_visible_in_tree():
		_start_prep()
	else:
		_start_work()

# --- Prep phase -------------------------------------------------------------

## The boss wants the player back at the spreadsheet with the distractions off
## before handing over the work itself.
func _start_prep() -> void:
	phase = Phase.PREP
	prep_tasks.append(GoToSpreadsheetTask.new(spreadsheet))
	prep_tasks.append(StopDistractionsTask.new(spreadsheet, activity_states))

	var descriptions: Array[String] = []
	for task in prep_tasks:
		descriptions.append(task.description)
	post_it_stack.start_prep_note(descriptions)
	spreadsheet.set_status_message(PREP_MESSAGE)

	for i in prep_tasks.size():
		prep_tasks[i].changed.connect(_on_prep_task_changed.bind(i))
		prep_tasks[i].start_task()
		# A prerequisite that is already met shows up checked right away.
		_sync_prep_item(i)
	_check_prep_finished()

func _on_prep_task_changed(index: int) -> void:
	if phase != Phase.PREP:
		return
	_sync_prep_item(index)
	_check_prep_finished()

func _sync_prep_item(index: int) -> void:
	post_it_stack.set_prep_item_checked(index, prep_tasks[index].check_completed())

func _check_prep_finished() -> void:
	for task in prep_tasks:
		if not task.check_completed():
			return

	# The tasks are dropped here, which takes their signal connections with them.
	prep_tasks.clear()
	post_it_stack.end_prep_note()
	_start_work()

# --- Work phase -------------------------------------------------------------

func _start_work() -> void:
	phase = Phase.WORK
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
	EventBus.punishment_task_completed.emit()
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

	phase = Phase.IDLE
	tasks.clear()
	current_index = 0
	post_it_stack.end_punishment()
	EventBus.punishment_ended.emit()

func _has_active_activities() -> bool:
	for is_running in activity_states.values():
		if is_running:
			return true
	return false

func _on_activity_started(source_id: StringName, _bonus: float) -> void:
	activity_states[source_id] = true

func _on_activity_ended(source_id: StringName) -> void:
	activity_states[source_id] = false
	if phase == Phase.WORK and current_index >= tasks.size():
		_try_finish()
